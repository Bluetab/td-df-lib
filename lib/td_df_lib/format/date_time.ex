defmodule TdDfLib.Format.DateTime do
  @moduledoc """
  Manages date and time formatting
  """

  @numeric_base_date ~D[1900-01-26]

  def convert_to_iso8601(nil, _type), do: {:ok, nil}
  def convert_to_iso8601("", _type), do: {:ok, ""}

  def convert_to_iso8601(%NaiveDateTime{} = datetime, "datetime"),
    do: {:ok, NaiveDateTime.to_iso8601(datetime)}

  def convert_to_iso8601(%NaiveDateTime{} = datetime, "date"),
    do:
      datetime
      |> NaiveDateTime.to_date()
      |> Date.to_iso8601()
      |> then(&{:ok, &1})

  def convert_to_iso8601(%Date{} = date, "date"), do: {:ok, Date.to_iso8601(date)}

  def convert_to_iso8601(%Date{} = date, "datetime") do
    {:ok, naive} = NaiveDateTime.new(date, ~T[00:00:00])
    {:ok, NaiveDateTime.to_iso8601(naive)}
  end

  def convert_to_iso8601(number, type) when is_integer(number) and type in ["date", "datetime"] do
    convert_numeric_to_iso8601(number, type)
  end

  def convert_to_iso8601(number, type) when is_float(number) and type in ["date", "datetime"] do
    convert_numeric_to_iso8601(number, type)
  end

  def convert_to_iso8601(content, type) when type not in ["date", "datetime"] do
    {:ok, content}
  end

  def convert_to_iso8601(content, type) when is_binary(content) do
    case String.trim(content) do
      "" -> {:ok, ""}
      value -> parse_string(value, type)
    end
  end

  def convert_to_iso8601(_, _), do: :error

  defp convert_numeric_to_iso8601(value, "date") do
    with {:ok, date} <- serial_to_date(trunc(value)) do
      {:ok, Date.to_iso8601(date)}
    end
  end

  defp convert_numeric_to_iso8601(value, "datetime") do
    {serial, seconds} = split_serial(value)

    with {:ok, date} <- serial_to_date(serial),
         {:ok, time} <- time_from_seconds(seconds),
         {:ok, naive} <- NaiveDateTime.new(date, time) do
      {:ok, NaiveDateTime.to_iso8601(naive)}
    end
  end

  defp split_serial(value) do
    serial = trunc(value)

    fraction =
      if is_float(value) do
        value - serial
      else
        0.0
      end

    total_seconds =
      fraction
      |> Kernel.*(86_400)
      |> round()

    cond do
      total_seconds >= 86_400 -> {serial + 1, 0}
      total_seconds < 0 -> {serial, 0}
      true -> {serial, total_seconds}
    end
  end

  defp time_from_seconds(seconds) when seconds in 0..86_399 do
    hour = div(seconds, 3600)
    minute = div(rem(seconds, 3600), 60)
    second = rem(seconds, 60)

    Time.new(hour, minute, second)
  end

  defp serial_to_date(serial) do
    {:ok, Date.add(@numeric_base_date, serial)}
  rescue
    ArgumentError -> :error
  end

  defp parse_numeric_string(value) do
    case Integer.parse(value) do
      {number, ""} ->
        {:ok, number}

      _ ->
        case Float.parse(value) do
          {number, ""} -> {:ok, number}
          _ -> :error
        end
    end
  end

  defp parse_string(value, "date") do
    case parse_numeric_string(value) do
      {:ok, number} ->
        convert_numeric_to_iso8601(number, "date")

      :error ->
        case parse_date(value) do
          {:ok, date} -> {:ok, Date.to_iso8601(date)}
          _ -> :error
        end
    end
  end

  defp parse_string(value, "datetime") do
    case parse_numeric_string(value) do
      {:ok, number} ->
        convert_numeric_to_iso8601(number, "datetime")

      :error ->
        parse_datetime_value(value)
    end
  end

  defp parse_string(_value, _type), do: :error

  defp parse_datetime_value(value) do
    value
    |> normalize_datetime_string()
    |> NaiveDateTime.from_iso8601()
    |> handle_datetime_parse(value)
  end

  defp handle_datetime_parse({:ok, naive}, _original) do
    {:ok, NaiveDateTime.to_iso8601(naive)}
  end

  defp handle_datetime_parse(_error, original) do
    original
    |> parse_datetime_with_separators()
    |> maybe_to_iso8601()
  end

  defp maybe_to_iso8601({:ok, naive}), do: {:ok, NaiveDateTime.to_iso8601(naive)}
  defp maybe_to_iso8601(_), do: :error

  defp parse_date(value) do
    case Date.from_iso8601(value) do
      {:ok, _} = result -> result
      _ -> parse_day_first_date(value)
    end
  end

  defp parse_day_first_date(value) do
    case String.split(value, ~r{[-/]}, trim: true) do
      [part1, part2, part3] ->
        with {first, ""} <- Integer.parse(part1),
             {second, ""} <- Integer.parse(part2),
             {third, ""} <- Integer.parse(part3),
             {:ok, date} <- build_date_from_parts(first, second, third, part1, part3) do
          {:ok, date}
        else
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp build_date_from_parts(year, month, day, part1, _part3)
       when year > 31 or byte_size(part1) == 4 do
    Date.new(year, month, day)
  end

  defp build_date_from_parts(day, month, year, _part1, part3) do
    cond do
      byte_size(part3) != 4 -> :error
      month == 2 and day > 28 -> :error
      true -> Date.new(year, month, day)
    end
  end

  defp parse_datetime_with_separators(value) do
    case String.split(value, ~r/[T\s]+/, trim: true, parts: 2) do
      [date_part, time_part] ->
        with {:ok, date} <- parse_date(date_part),
             {:ok, time} <- Time.from_iso8601(time_part),
             {:ok, naive} <- NaiveDateTime.new(date, time) do
          {:ok, naive}
        else
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp normalize_datetime_string(value) do
    if String.contains?(value, "T") do
      value
    else
      String.replace(value, " ", "T")
    end
  end
end
