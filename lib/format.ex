defmodule TdDfLib.Format do
  @moduledoc """
  Manages content formatting
  """
  alias TdDfLib.RichText

  def apply_template(nil, _), do: nil

  def apply_template(%{} = content, _) when map_size(content) == 0, do: nil

  def apply_template(%{} = content, %{content: fields}) do
    content
    |> default_values(fields)
    |> search_values(fields)
  end

  def apply_template(_, _), do: nil

  def default_values(content, fields) do
    field_names = Enum.map(fields, &Map.get(&1, "name"))

    content
      |> Map.take(field_names)
      |> set_default_values(fields)
  end

  def search_values(content, fields) do
    field_names =
      fields
      |> Enum.filter(&Map.has_key?(&1, "type"))
      |> Enum.filter(fn %{"type" => type} -> type == "enriched_text" end)
      |> Enum.map(&Map.get(&1, "name"))

    search_values =
      content
      |> Map.take(field_names)
      |> set_search_values()

    Map.merge(content, search_values)
  end

  def set_default_values(content, fields) do
    fields
    |> Enum.reduce(content, &set_default_value(&2, &1))
  end

  def set_search_values(content) do
    content
    |> Enum.reduce(Map.new(), &set_search_value(&1, &2))
  end

  defp set_search_value({key, value}, acc) when is_map(value) do
    Map.put(acc, key, RichText.to_plain_text(value))
  end

  defp set_search_value({key, value}, acc) do
    Map.put(acc, key, value)
  end

  def set_default_value(content, %{"name" => name, "default" => default}) do
    Map.put_new(content, name, default)
  end

  def set_default_value(content, %{"name" => name, "cardinality" => "*", "values" => values})
      when not is_nil(values) do
    Map.put_new(content, name, [""])
  end

  def set_default_value(content, %{"name" => name, "cardinality" => "+", "values" => values})
      when not is_nil(values) do
    Map.put_new(content, name, [""])
  end

  def set_default_value(content, %{"name" => name, "values" => values}) when not is_nil(values) do
    Map.put_new(content, name, "")
  end

  def set_default_value(content, %{}), do: content
end
