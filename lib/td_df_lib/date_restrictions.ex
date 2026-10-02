defmodule TdDfLib.DateRestrictions do
  @units ~w(days weeks months years)

  @type field_type :: String.t()
  @type restrictions :: map() | nil

  def resolve(restrictions, field_type, now \\ nil)

  def resolve(restrictions, field_type, now) when field_type in ["date", "datetime"] do
    restrictions = restrictions || %{}
    reference = reference_now(field_type, now)
    {lows, highs} = bounds(restrictions, effective_between(restrictions), reference, field_type)

    %{
      "min" => lows |> pick(field_type, :min) |> format(field_type),
      "max" => highs |> pick(field_type, :max) |> format(field_type)
    }
  end

  def resolve(_restrictions, _field_type, _now), do: %{"min" => nil, "max" => nil}

  defp bounds(restrictions, range, reference, field_type) do
    {low, high} =
      {limit(Map.get(restrictions, "min_date"), reference, :min, field_type),
       limit(Map.get(restrictions, "max_date"), reference, :max, field_type)}

    case range do
      nil ->
        {candidates(low, nil), candidates(high, nil)}

      {:static, start_iso, end_iso} ->
        {candidates(low, parse_bound(start_iso, :min, field_type)),
         candidates(high, parse_bound(end_iso, :max, field_type))}

      {:dynamic, from_side, to_side} ->
        {candidates(low, shift(from_side, reference, field_type)),
         candidates(high, shift(to_side, reference, field_type))}
    end
  end

  defp candidates(nil, nil), do: []
  defp candidates(a, b), do: Enum.reject([a, b], &is_nil/1)

  defp limit(%{"mode" => "static", "value" => value}, _reference, :min, field_type),
    do: parse_bound(value, :min, field_type)

  defp limit(%{"mode" => "static", "value" => value}, _reference, :max, field_type),
    do: parse_bound(value, :max, field_type)

  defp limit(
         %{"mode" => "dynamic", "amount" => amount, "unit" => unit},
         reference,
         _which,
         field_type
       ),
       do: shift(%{"amount" => amount, "unit" => unit}, reference, field_type)

  defp limit(_other, _reference, _which, _field_type), do: nil

  defp effective_between(%{"between" => %{"mode" => "static", "start" => s, "end" => e}}),
    do: {:static, s, e}

  defp effective_between(%{"between" => %{"mode" => "dynamic", "from" => from, "to" => to}}),
    do: {:dynamic, from, to}

  defp effective_between(restrictions) do
    case {Map.get(restrictions, "between_start"), Map.get(restrictions, "between_end")} do
      {nil, nil} -> nil
      {start_iso, end_iso} -> {:static, start_iso, end_iso}
    end
  end

  defp shift(%{"amount" => amount, "unit" => unit}, reference, field_type) do
    with true <- unit in @units,
         {:ok, amount} <- to_integer(amount) do
      apply_shift(reference, amount, unit, field_type)
    else
      _ -> nil
    end
  end

  defp shift(_other, _reference, _field_type), do: nil

  defp apply_shift(reference, amount, unit, _field_type) do
    case Timex.shift(reference, [{String.to_atom(unit), amount}]) do
      {:error, _reason} -> nil
      shifted -> shifted
    end
  end

  defp to_integer(amount) when is_integer(amount), do: {:ok, amount}
  defp to_integer(amount) when is_binary(amount), do: Integer.parse(amount)
  defp to_integer(_amount), do: :error

  defp reference_now("date", nil), do: Date.utc_today()
  defp reference_now("date", %Date{} = date), do: date
  defp reference_now("datetime", nil), do: DateTime.to_naive(DateTime.utc_now())
  defp reference_now("datetime", %NaiveDateTime{} = ndt), do: ndt
  defp reference_now(_field_type, _now), do: nil

  defp parse(value, "date") do
    with true <- is_binary(value),
         {:ok, date} <- Date.from_iso8601(value) do
      date
    else
      _ -> nil
    end
  end

  defp parse(value, "datetime") do
    with true <- is_binary(value),
         {:ok, ndt} <- naive(value) do
      ndt
    else
      _ -> nil
    end
  end

  defp parse(_value, _field_type), do: nil

  defp parse_bound(value, :max, "datetime") when is_binary(value) do
    if String.contains?(value, "T"),
      do: parse(value, "datetime"),
      else: parse(value <> "T23:59:00", "datetime")
  end

  defp parse_bound(value, _which, field_type), do: parse(value, field_type)

  defp naive(value) do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, ndt} ->
        {:ok, ndt}

      _ ->
        with false <- String.contains?(value, "T"),
             {:ok, ndt} <- NaiveDateTime.from_iso8601(value <> "T00:00:00") do
          {:ok, ndt}
        else
          _ -> NaiveDateTime.from_iso8601(value <> ":00")
        end
    end
  end

  defp pick([], _field_type, _direction), do: nil

  defp pick([only], _field_type, _direction), do: only

  defp pick(candidates, field_type, direction) do
    Enum.reduce(candidates, fn candidate, acc ->
      compare(candidate, acc, field_type, direction)
    end)
  end

  defp compare(_candidate, nil, _field_type, _direction), do: nil

  defp compare(candidate, acc, "date", direction),
    do: (tightest?(Date.compare(candidate, acc), direction) && candidate) || acc

  defp compare(candidate, acc, "datetime", direction),
    do: (tightest?(NaiveDateTime.compare(candidate, acc), direction) && candidate) || acc

  defp tightest?(:gt, :min), do: true
  defp tightest?(:lt, :max), do: true
  defp tightest?(_comparison, _direction), do: false

  defp format(nil, _field_type), do: nil
  defp format(%Date{} = date, "date"), do: Date.to_iso8601(date)
  defp format(%Date{} = date, "datetime"), do: Date.to_iso8601(date) <> "T00:00"

  defp format(%NaiveDateTime{} = ndt, "datetime"),
    do: ndt |> NaiveDateTime.to_iso8601() |> String.slice(0, 16)

  defp format(%NaiveDateTime{} = ndt, "date"),
    do: ndt |> NaiveDateTime.to_date() |> Date.to_iso8601()

  def validate_value(restrictions, value, field_type, now \\ nil, opts \\ [])

  def validate_value(_restrictions, value, _field_type, _now, opts)
      when value in [nil, "", []] do
    _ = opts
    :ok
  end

  def validate_value(restrictions, values, field_type, now, opts)
      when is_list(values) and field_type in ["date", "datetime"] do
    if unchanged?(values, opts) do
      :ok
    else
      reference = reference_now(field_type, now)
      Enum.find_value(values, :ok, &first_error([restrictions, &1, field_type, reference]))
    end
  end

  def validate_value(restrictions, value, field_type, now, opts)
      when field_type in ["date", "datetime"] do
    if unchanged?(value, opts) do
      :ok
    else
      check_one(restrictions, value, field_type, reference_now(field_type, now))
    end
  end

  def validate_value(_restrictions, _value, _field_type, _now, _opts), do: :ok

  defp first_error([restrictions, value, field_type, reference]) do
    case check_one(restrictions, value, field_type, reference) do
      :ok -> nil
      error -> error
    end
  end

  defp unchanged?(value, opts),
    do: Keyword.has_key?(opts, :previous_value) and opts[:previous_value] == value

  defp check_one(restrictions, value, field_type, reference) do
    %{"min" => min_iso, "max" => max_iso} = resolve(restrictions, field_type, reference)
    value = parse(value, field_type)

    cond do
      is_nil(value) -> :ok
      below?(value, parse(min_iso, field_type), field_type) -> out_of_range(min_iso)
      above?(value, parse(max_iso, field_type), field_type) -> out_of_range(max_iso)
      true -> :ok
    end
  end

  defp below?(_value, nil, _field_type), do: false
  defp below?(%Date{} = value, %Date{} = bound, "date"), do: Date.compare(value, bound) == :lt

  defp below?(%NaiveDateTime{} = v, %NaiveDateTime{} = b, "datetime"),
    do: NaiveDateTime.compare(v, b) == :lt

  defp above?(_value, nil, _field_type), do: false
  defp above?(%Date{} = value, %Date{} = bound, "date"), do: Date.compare(value, bound) == :gt

  defp above?(%NaiveDateTime{} = v, %NaiveDateTime{} = b, "datetime"),
    do: NaiveDateTime.compare(v, b) == :gt

  defp out_of_range(limit),
    do: {:error, {"errors.date_restrictions.out_of_range", [limit: limit, fixed_name: true]}}
end
