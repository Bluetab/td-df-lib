defmodule TdDfLib.Parser do
  @moduledoc """
  Functions for importing and exporting content on text format
  """

  alias TdCache.DomainCache
  alias TdCache.HierarchyCache
  alias TdCache.I18nCache
  alias TdDfLib.Format

  def append_parsed_fields(acc, fields, content, opts \\ []) do
    ctx =
      context_for_fields(fields, Keyword.get(opts, :domain_type, :with_domain_external_id))
      |> Map.put("lang", Keyword.get(opts, :lang))

    Enum.reduce(
      fields,
      acc,
      &(&2 ++ [field_to_string(&1, content, ctx)])
    )
  end

  def format_content(
        %{
          content: params_content,
          content_schema: content_schema,
          domain_ids: domain_ids
        } = params
      )
      when not is_nil(params_content) do
    lang = Map.get(params, :lang, get_default_lang())
    content_values = get_from_content(params_content, "value")
    content = Format.apply_template(content_values, content_schema, domain_ids: domain_ids)

    content_schema
    |> Enum.filter(fn %{"type" => schema_type, "cardinality" => cardinality} = schema ->
      schema_type in ["url", "enriched_text", "integer", "float", "domain", "hierarchy"] or
        (schema_type in ["string", "user"] and cardinality in ["*", "+"]) or
        match?(%{"fixed" => _}, Map.get(schema, "values")) or
        match?(%{"switch" => _}, Map.get(schema, "values"))
    end)
    # credo:disable-for-next-line
    |> Enum.filter(fn %{"name" => name} ->
      field_content = Map.get(content, name)
      not is_nil(field_content) and is_binary(field_content)
    end)
    |> Enum.into(content, &format_field(&1, content, lang))
    |> merge_with_content(params_content)
  end

  def format_content(_params), do: nil

  defp format_field(schema, content, lang) do
    content =
      %{
        "label" => Map.get(schema, "label"),
        "content" => Map.get(content, Map.get(schema, "name")),
        "type" => Map.get(schema, "type"),
        "cardinality" => Map.get(schema, "cardinality"),
        "values" => Map.get(schema, "values"),
        "lang" => lang
      }
      |> Format.format_field()
      |> format_content_errors()

    {Map.get(schema, "name"), content}
  end

  defp format_content_errors(content) when is_list(content) do
    case Enum.find(content, fn cont -> match?({:error, _}, cont) end) do
      {:error, _} = error -> error
      _ -> content
    end
  end

  defp format_content_errors(content_value), do: content_value

  defp context_for_fields(fields, domain_type) do
    Enum.reduce(fields, %{}, fn
      %{"type" => "domain"}, %{domains: %{}} = ctx ->
        ctx

      %{"type" => "domain"}, ctx ->
        {:ok, domains} = domain_content(domain_type)

        Map.put(ctx, :domains, domains)

      %{
        "type" => "hierarchy",
        "values" => %{"hierarchy" => %{"id" => hierarchy_id}}
      },
      ctx ->
        {:ok, nodes} = HierarchyCache.get(hierarchy_id, :nodes)
        Map.update(ctx, :hierarchy, %{hierarchy_id => nodes}, &Map.put(&1, hierarchy_id, nodes))

      _, ctx ->
        ctx
    end)
  end

  def get_from_content(content, content_key) do
    # TODO: Rise exception if is not a map or it does not have content_key
    content
    |> Enum.map(fn {key, value} ->
      if is_map(value) do
        if Map.has_key?(value, content_key) do
          {key, Map.get(value, content_key, "")}
        else
          {key, nil}
        end
      else
        if content_key == "value" do
          {key, value}
        else
          {key, nil}
        end
      end
    end)
    |> Enum.into(%{})
  end

  def merge_with_content(content, original_content) do
    content
    |> Enum.map(fn {key, value} ->
      original_content
      |> Map.get(key)
      |> case do
        nil -> {key, %{"value" => value, "origin" => "default"}}
        content_value -> {key, Map.put(content_value, "value", value)}
      end
    end)
    |> Map.new()
  end

  defp domain_content(:with_domain_name), do: DomainCache.id_to_name_map()
  defp domain_content(:with_domain_external_id), do: DomainCache.id_to_external_id_map()

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

  defp parse_field(
         %{"type" => "hierarchy", "values" => %{"hierarchy" => %{"id" => hierarchy_id}}},
         value,
         %{
           hierarchy: hierarchy
         }
       )
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
         %{"label" => label, "type" => "string", "values" => %{"fixed_tuple" => fixed_tuple}},
         value,
         %{"lang" => lang}
       ),
       do:
         fixed_tuple
         |> Enum.find(fn %{"value" => map_value} -> value == map_value end)
         |> then(fn
           %{"text" => text} ->
             I18nCache.get_definition(lang, "fields." <> label <> "." <> text, default_value: text)

           _ ->
             nil
         end)

  defp parse_field(
         %{"label" => label, "type" => "string", "values" => map_values},
         value,
         %{"lang" => lang}
       )
       when is_map_key(map_values, "fixed") or is_map_key(map_values, "switch") do
    I18nCache.get_definition(lang, "fields." <> label <> "." <> value, default_value: value)
  end

  defp parse_field(_, value, _), do: value

  defp value_to_list(nil), do: []
  defp value_to_list([""]), do: []
  defp value_to_list(""), do: []
  defp value_to_list(content) when is_list(content), do: content
  defp value_to_list(content), do: [content]

  def get_default_lang do
    {:ok, lang} = I18nCache.get_default_locale()
    lang
  end
end
