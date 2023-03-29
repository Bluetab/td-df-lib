defmodule TdDfLib.Parser do
  @moduledoc """
  Functions for importing and exporting content on text format
  """

  alias TdCache.DomainCache
  alias TdCache.HierarchyCache
  alias TdDfLib.Format

  def append_parsed_fields(acc, fields, content) do
    ctx = context_for_fields(fields)

    Enum.reduce(
      fields,
      acc,
      &(&2 ++ [field_to_string(&1, content, ctx)])
    )
  end

  def format_content(%{content: content, content_schema: content_schema, domain_ids: domain_ids})
      when not is_nil(content) do
    content = Format.apply_template(content, content_schema, domain_ids: domain_ids)

    content_schema
    |> Enum.filter(fn %{"type" => schema_type, "cardinality" => cardinality} ->
      schema_type in ["url", "enriched_text", "integer", "float", "domain", "hierarchy"] or
        (schema_type in ["string", "user"] and cardinality in ["*", "+"])
    end)
    # credo:disable-for-next-line
    |> Enum.filter(fn %{"name" => name} ->
      field_content = Map.get(content, name)
      not is_nil(field_content) and is_binary(field_content)
    end)
    |> Enum.into(content, &format_field(&1, content))
  end

  def format_content(_params), do: nil

  defp format_field(schema, content) do
    {Map.get(schema, "name"),
     Format.format_field(%{
       "content" => Map.get(content, Map.get(schema, "name")),
       "type" => Map.get(schema, "type"),
       "cardinality" => Map.get(schema, "cardinality"),
       "values" => Map.get(schema, "values")
     })}
  end

  defp context_for_fields(fields) do
    Enum.reduce(fields, %{}, fn
      %{"type" => "domain"}, %{domains: %{}} = ctx ->
        ctx

      %{"type" => "domain"}, ctx ->
        {:ok, domains} = DomainCache.id_to_external_id_map()
        Map.put(ctx, :domains, domains)

      %{
        "type" => "hierarchy",
        "values" => %{"hierarchy" => hierarchy_id}
      },
      ctx ->
        {:ok, nodes} = HierarchyCache.get(hierarchy_id, :nodes)
        Map.update(ctx, :hierarchy, %{hierarchy_id => nodes}, &Map.put(&1, hierarchy_id, nodes))

      _, ctx ->
        ctx
    end)
  end

  defp field_to_string(_field, nil, _ctx), do: ""

  defp field_to_string(%{"name" => name} = field, content, domain_map) do
    content
    |> get_field_value(name)
    |> value_to_list()
    |> Enum.map(&parse_field(field, &1, domain_map))
    |> Enum.reject(&is_nil/1)
    |> Enum.join("|")
  end

  defp get_field_value(content, name),
    do: Map.get(content, name) || Map.get(content, String.to_atom(name))

  defp parse_field(%{"type" => "url"}, %{url_value: url_value}, _ctx), do: url_value
  defp parse_field(%{"type" => "url"}, %{"url_value" => url_value}, _ctx), do: url_value
  defp parse_field(%{"type" => "url"}, _, _ctx), do: nil

  defp parse_field(%{"type" => "domain"}, value, %{domains: domains}), do: Map.get(domains, value)

  defp parse_field(%{"type" => "table"}, _value, _ctx), do: ""
  defp parse_field(%{"type" => "system"}, value, _ctx), do: Map.get(value, :name, "")

  defp parse_field(%{"type" => "hierarchy", "values" => %{"hierarchy" => hierarchy_id}}, value, %{
         hierarchy: hierarchy
       })
       when is_binary(value) do
    hierarchy
    |> Map.get(hierarchy_id)
    |> Enum.find(fn %{"node_id" => node_id} ->
      [_hierarchy_id, content_node_id] = String.split(value, "_")
      node_id === String.to_integer(content_node_id)
    end)
    |> then(fn
      %{"path" => path} -> path
      _ -> nil
    end)
  end

  defp parse_field(
         %{"type" => "string", "values" => %{"fixed_tuple" => fixed_tuple}},
         value,
         _ctx
       ),
       do:
         fixed_tuple
         |> Enum.find(fn %{"value" => map_value} -> value == map_value end)
         |> then(fn
           %{"text" => text} -> text
           _ -> nil
         end)

  defp parse_field(_, value, _), do: value

  defp value_to_list(nil), do: []
  defp value_to_list([""]), do: []
  defp value_to_list(""), do: []
  defp value_to_list(content) when is_list(content), do: content
  defp value_to_list(content), do: [content]
end
