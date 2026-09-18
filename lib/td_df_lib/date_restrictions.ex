defmodule TdDfLib.DateRestrictions do
  @moduledoc """
  Pure validation of date/datetime restriction **values** against the
  restriction definition. Decoupled from Ecto so it can be reused by any
  consumer of `td-df-lib` that fills out a template (concepts, ingests,
  implementations, ...).

  This module is *not* responsible for validating the shape of the
  restriction JSON — that belongs to the template owner (`td-df`) because
  template definition (CRUD) is its domain.

  A restriction value is a map with any of:

    * `"max_date"` / `"min_date"`: either `%{"mode" => "static", "value" => iso}`
      or `%{"mode" => "dynamic", "amount" => integer, "unit" => "days" | "weeks" | "months" | "years"}`.
      The amount is signed: positive = future (today + amount), negative = past
      (today - |amount|).

    * `"between"`: either `%{"mode" => "static", "start" => iso, "end" => iso}`
      or `%{"mode" => "dynamic", "from" => %{amount, unit}, "to" => %{amount, unit}}`.
      Both `from` and `to` use signed amounts.

    * Legacy flat shape: `%{"between_start" => iso, "between_end" => iso}`.

  Functions return either `:ok` or `{:error, %{key: ..., values: ...,
  fallback: ...}}`.
  """

  alias Timex

  @type field_type :: String.t()
  @type restrictions :: map() | nil
  @type iso_value :: String.t()
  @type error :: %{
          key: String.t(),
          values: map(),
          fallback: String.t()
        }
  @type now :: Date.t() | NaiveDateTime.t() | nil

  # ----- Public API -----

  @doc """
  Validates a value against restrictions. `now` is the reference date used
  by dynamic restrictions (defaults to today's date / now in UTC).

  The shape of `restrictions` is assumed valid — shape validation is the
  responsibility of the template owner (see
  `TdDf.Templates.DateRestrictionShape`).
  """
  @spec validate_value(restrictions(), iso_value() | nil, field_type(), now()) ::
          :ok | {:error, error()}
  def validate_value(restrictions, value, type, now \\ nil)
      when type in ["date", "datetime"] do
    with :ok <- ensure_value(value),
         {:ok, parsed_value} <- parse_value(value, type),
         {:ok, ref_now} <- resolve_now(now, type),
         :ok <- check_limit(parsed_value, Map.get(restrictions || %{}, "max_date"), :max, type, ref_now),
         :ok <- check_limit(parsed_value, Map.get(restrictions || %{}, "min_date"), :min, type, ref_now),
         :ok <- check_between(parsed_value, restrictions || %{}, type, ref_now) do
      :ok
    end
  end

  # ----- Value validation -----

  defp ensure_value(nil), do: :ok
  defp ensure_value(""), do: :ok
  defp ensure_value(_), do: :ok

  defp parse_value(value, "date") do
    case Date.from_iso8601(value) do
      {:ok, date} -> {:ok, date}
      _ -> error("invalid.date_format", %{})
    end
  end

  defp parse_value(value, "datetime") do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, ndt} ->
        {:ok, ndt}

      _ ->
        case NaiveDateTime.from_iso8601(value <> ":00") do
          {:ok, ndt} -> {:ok, ndt}
          _ -> error("invalid.datetime_format", %{})
        end
    end
  end

  defp resolve_now(nil, "date"), do: {:ok, Date.utc_today()}
  defp resolve_now(nil, "datetime"), do: {:ok, DateTime.to_naive(DateTime.utc_now())}
  defp resolve_now(%Date{} = d, "date"), do: {:ok, d}
  defp resolve_now(%NaiveDateTime{} = ndt, "datetime"), do: {:ok, ndt}
  defp resolve_now(now, _type), do: {:ok, now}

  defp check_limit(_value, nil, _direction, _type, _now), do: :ok

  defp check_limit(value, %{"mode" => "static", "value" => v}, direction, type, _now) do
    case parse_value(v, type) do
      {:ok, limit} ->
        if exceeds?(value, limit, direction) do
          limit_error(direction, format_value(limit))
        else
          :ok
        end

      _ ->
        :ok
    end
  end

  defp check_limit(value, %{"mode" => "dynamic", "amount" => a, "unit" => u}, direction, _type, now) do
    limit = compute_dynamic_limit(now, %{"amount" => a, "unit" => u})

    if exceeds?(value, limit, direction) do
      limit_error(direction, format_value(limit))
    else
      :ok
    end
  end

  defp check_limit(_, _, _, _, _), do: :ok

  defp check_between(_value, restrictions, type, now) do
    case effective_between(restrictions, type) do
      nil ->
        :ok

      {:static, start_str, end_str} ->
        with {:ok, start_val} <- parse_value(start_str, type),
             {:ok, end_val} <- parse_value(end_str, type) do
          if compare(start_val, end_val) == :gt do
            error("errors.date_restrictions.range_start_must_be_before_end", %{})
          else
            :ok
          end
        end

      {:dynamic, from_side, to_side} ->
        from_val = compute_dynamic_limit(now, from_side)
        to_val = compute_dynamic_limit(now, to_side)

        case compare(from_val, to_val) do
          :gt -> error("errors.date_restrictions.range_start_must_be_before_end", %{})
          _ -> :ok
        end
    end
  end

  defp effective_between(restrictions, _type) do
    case Map.get(restrictions, "between") do
      %{"mode" => "static", "start" => s, "end" => e} ->
        {:static, s, e}

      %{"mode" => "dynamic", "from" => f, "to" => t} ->
        {:dynamic, f, t}

      _ ->
        case {Map.get(restrictions, "between_start"), Map.get(restrictions, "between_end")} do
          {nil, nil} -> nil
          {s, e} -> {:static, s, e}
        end
    end
  end

  # ----- Helpers -----

  defp exceeds?(value, limit, :max), do: compare(value, limit) == :gt
  defp exceeds?(value, limit, :min), do: compare(value, limit) == :lt

  defp compare(%Date{} = a, %Date{} = b), do: Date.compare(a, b)

  defp compare(%NaiveDateTime{} = a, %NaiveDateTime{} = b),
    do: NaiveDateTime.compare(a, b)

  defp compute_dynamic_limit(now, %{"amount" => a, "unit" => u}) do
    opts = [{String.to_atom(u), a}]
    result = Timex.shift(now, opts)
    coerce_to_struct(result, now)
  end

  # NOTE: dynamic limits intentionally preserve the time component of `now`.
  # "max 4 days from now" means now+4d exactly, so picking the limit day at
  # any hour up to the current time is valid. Normalizing to 00:00:00 here
  # (as done previously) wrongly rejected every hour of the limit day for
  # datetime fields. Kept in sync with the front-end's shiftFromOptions.

  defp coerce_to_struct(%Date{} = d, _), do: d
  defp coerce_to_struct(%NaiveDateTime{} = ndt, _), do: ndt
  defp coerce_to_struct(%DateTime{} = dt, _), do: DateTime.to_naive(dt)
  defp coerce_to_struct(_, _), do: nil

  defp format_value(%Date{} = d), do: Date.to_iso8601(d)
  defp format_value(%NaiveDateTime{} = ndt), do: NaiveDateTime.to_iso8601(ndt)

  defp limit_error(:max, limit_str),
    do: error("errors.date_restrictions.must_be_on_or_before", %{limit: limit_str})

  defp limit_error(:min, limit_str),
    do: error("errors.date_restrictions.must_be_on_or_after", %{limit: limit_str})

  defp error(key, values) do
    {:error, %{key: key, values: values, fallback: fallback_for(key, values)}}
  end

  defp fallback_for("errors.date_restrictions.must_be_on_or_before", %{limit: l}),
    do: "must be on or before #{l}"

  defp fallback_for("errors.date_restrictions.must_be_on_or_after", %{limit: l}),
    do: "must be on or after #{l}"

  defp fallback_for("errors.date_restrictions.range_start_must_be_before_end", _),
    do: "range start must be before range end"

  defp fallback_for(key, _), do: key
end
