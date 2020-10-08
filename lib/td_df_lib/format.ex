defmodule TdDfLib.Format do
  @moduledoc """
  Manages content formatting
  """
  alias TdCache.SystemCache
  alias TdDfLib.RichText

  @format_types ["enriched_text", "system"]

  def apply_template(nil, _), do: %{}

  def apply_template(_, nil), do: %{}

  def apply_template(%{} = content, fields) do
    content
    |> default_values(fields)
    |> cached_values(fields)
  end

  def enrich_content_values(%{} = content, %{content: fields}) do
    fields = flatten_content_fields(fields)
    cached_values(content, fields)
  end

  def enrich_content_values(content, _), do: content

  def search_values(%{} = content, %{content: fields}) do
    fields = flatten_content_fields(fields)

    content
    |> apply_template(fields)
    |> drop_values(fields)
    |> format_search_values(fields)
  end

  def search_values(_, _), do: nil

  def flatten_content_fields(content) do
    Enum.flat_map(content, fn %{"name" => group, "fields" => fields} ->
      Enum.map(fields, &Map.put(&1, "group", group))
    end)
  end

  defp cached_values(content, fields) do
    keys = Map.keys(content)
    
    fields =
      fields
      |> Enum.filter(&Map.has_key?(&1, "type"))
      |> Enum.filter(fn %{"type" => type} -> type == "system" end)
      |> Enum.filter(fn %{"name" => name} -> name in keys end)

    field_names = Enum.map(fields, &Map.get(&1, "name"))

    cached_values =
      content
      |> Map.take(field_names)
      |> set_cached_values(fields)

    Map.merge(content, cached_values)
  end

  defp drop_values(content, fields) do
    keys =
      fields
      |> Enum.filter(&(Map.get(&1, "type") == "image"))
      |> Enum.map(&Map.get(&1, "name"))

    Map.drop(content, keys)
  end

  def format_search_values(content, fields) do
    fields =
      fields
      |> Enum.filter(&Map.has_key?(&1, "type"))
      |> Enum.filter(fn %{"type" => type} -> type in @format_types end)

    field_names = Enum.map(fields, &Map.get(&1, "name"))

    search_values =
      content
      |> Map.take(field_names)
      |> set_search_values(fields)

    Map.merge(content, search_values)
  end

  def default_values(content, fields) do
    field_names = Enum.map(fields, &Map.get(&1, "name"))

    content
    |> Map.take(field_names)
    |> set_default_values(fields)
  end

  def set_default_values(content, fields) do
    Enum.reduce(fields, content, &set_default_value(&2, &1))
  end

  def set_search_values(content, fields) do
    Enum.reduce(fields, content, &set_search_value(&1, &2))
  end

  defp set_search_value(%{"name" => name, "type" => "enriched_text"}, acc) do
    Map.put(acc, name, RichText.to_plain_text(Map.get(acc, name)))
  end

  defp set_search_value(%{"name" => name, "type" => "system"}, acc) do
    case Map.get(acc, name) do
      value = %{} -> Map.put(acc, name, [value])
      value -> Map.put(acc, name, value)
    end
  end

  defp set_search_value(_field, acc), do: acc

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

  def format_field(%{"content" => content, "type" => "url"}) do
    link_value = [
      %{
        "url_name" => content,
        "url_value" => content
      }
    ]

    link_value
  end

  def format_field(%{
        "type" => "string",
        "content" => content,
        "values" => %{"fixed_tuple" => fixed_tuples}
      }) do
    fixed_tuple = Enum.find(fixed_tuples, fn %{"value" => value} -> value == content end)

    new_content =
      case fixed_tuple do
        nil ->
          fixed_tuples
          |> Enum.find(%{"value" => content}, fn %{"text" => text} -> text == content end)
          |> Map.get("value")

        _fixed_tuple ->
          content
      end

    [new_content]
  end

  def format_field(%{"content" => content, "type" => "string"}) do
    [content]
  end

  def format_field(%{"content" => content, "type" => "enriched_text"}) do
    RichText.to_rich_text(content)
  end

  def format_field(%{"content" => content, "type" => "user", "cardinality" => cardinality})
      when cardinality in ["+", "*"] and is_binary(content) do
    [content]
  end

  def format_field(%{"content" => content, "type" => "integer"}) when is_binary(content) do
    String.to_integer(content)
  end

  def format_field(%{"content" => content, "type" => "float"}) when is_binary(content) do
    String.to_float(content)
  end

  def format_field(%{
        "content" => content
      }),
      do: content

  defp set_cached_values(content, fields) do
    Enum.reduce(fields, content, &set_cached_value(&1, &2))
  end

  defp set_cached_value(%{"name" => name, "type" => "system", "cardinality" => cardinality}, acc) do
    Map.put(acc, name, format_system(Map.get(acc, name), cardinality))
  end

  defp set_cached_value(_field, acc), do: acc

  defp format_system(%{} = system, _cardinality) do
    id = Map.get(system, "id")

    case SystemCache.get(id) do
      {:ok, system} -> system
      _ -> system
    end
  end

  defp format_system([_ | _] = systems, cardinality) do
    Enum.map(systems, &format_system(&1, cardinality))
  end

  defp format_system(external_id, cardinality) when is_binary(external_id) do
    {:ok, m} = SystemCache.external_id_to_id_map()

    system =
      m
      |> Map.get(external_id)
      |> SystemCache.get()
      |> case do
        {:ok, system} -> system
        _ -> nil
      end

    apply_cardinality(system, cardinality)
  end

  defp format_system(system, _cardinality), do: system

  defp apply_cardinality(system = %{}, cardinality) when cardinality in ["*", "+"], do: [system]

  defp apply_cardinality(system, _cardinality), do: system
end
