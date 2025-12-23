defmodule TdDfLib.Parser do
  @moduledoc """
  Functions for importing and exporting content on text format
  """

  alias TdCache.DomainCache
  alias TdCache.HierarchyCache
  alias TdCache.I18nCache
  alias TdDfLib.Format
  alias TdDfLib.Format.DateTime, as: FormatDateTime
  alias TdDfLib.I18n

  NimbleCSV.define(Parser.Table, separator: "\;", escape: "\"")

  @schema_types ~w(url enriched_text integer float domain hierarchy table dynamic_table)
  @multiple_cardinality_schema_types ~w(string user user_group)
  @date_types ~w(date datetime)

  @doc """
  Parses field values from content and appends them to the accumulator.

  ## Parameters
  - `acc` - Accumulator list to append results to
  - `fields` - List of field definitions
  - `content` - Map containing field values
  - `opts` - Options keyword list (domain_type, lang, translations, locales, xlsx)
  - `context` - Optional pre-built context map. If not provided, context will be built internally.

  ## Examples

      # Without pre-built context (backward compatible)
      append_parsed_fields([], fields, content, [lang: "en", domain_type: :with_domain_external_id])

      # With pre-built context (optimized)
      context = context_for_fields(fields, :with_domain_external_id) |> Map.put("lang", "en")
      append_parsed_fields([], fields, content, [lang: "en"], context)
  """
  def append_parsed_fields(acc, fields, content, opts \\ [], context \\ nil) do
    opts = normalize_opts(opts)

    ctx =
      context ||
        fields
        |> context_for_fields(Keyword.get(opts, :domain_type, :with_domain_external_id))
        |> Map.put("lang", Keyword.get(opts, :lang))

    fields_to_string(acc, fields, content, ctx, opts)
  end

  def format_content(
        %{
          content: params_content,
          content_schema: content_schema,
          domain_ids: domain_ids
        } = params
      )
      when not is_nil(params_content) do
    lang = get_default_lang(Map.get(params, :lang))

    template_content =
      Format.apply_template(params_content, content_schema, domain_ids: domain_ids)

    template_content
    |> get_from_content("value")
    |> format_fields(content_schema, lang)
    |> merge_with_content(template_content)
  end

  def format_content(_params), do: nil

  def format_fields(content, content_schema, lang) do
    content_schema
    |> Enum.filter(fn %{"type" => schema_type, "cardinality" => cardinality} = schema ->
      schema_type in @schema_types or schema_type in @date_types or
        (schema_type in @multiple_cardinality_schema_types and cardinality in ["*", "+"]) or
        match?(%{"fixed" => _}, Map.get(schema, "values")) or
        match?(%{"switch" => _}, Map.get(schema, "values"))
    end)
    # credo:disable-for-next-line
    |> Enum.filter(fn %{"name" => name, "type" => type} ->
      field_content = Map.get(content, name)
      not is_nil(field_content) and (is_binary(field_content) or type in @date_types)
    end)
    |> Enum.into(content, &format_field(&1, content, lang))
  end

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

  @doc """
  Builds a context map for field parsing by analyzing field types and loading necessary cache data.

  This function examines the fields list and pre-loads cache data needed for parsing:
  - Domain fields: Loads domain ID to external_id/name mapping
  - Hierarchy fields: Loads hierarchy nodes by hierarchy ID

  ## Parameters
  - `fields` - List of field definitions
  - `domain_type` - Atom indicating domain mapping type (`:with_domain_external_id` or `:with_domain_name`)
  - `domains_name` - Map of domain ID to name (optional, only for 4-arity version)
  - `domains_external_id` - Map of domain ID to external_id (optional, only for 4-arity version)

  ## Returns
  A context map containing:
  - `:domains` - Map of domain ID to external_id/name (if domain fields present)
  - `:hierarchy` - Map of hierarchy_id to nodes (if hierarchy fields present)

  ## Examples

      # Using 2-arity version (loads cache internally)
      context = context_for_fields(fields, :with_domain_external_id)
      # %{domains: %{1 => "domain_ext_id", 2 => "another_ext_id"}}

      # Using 4-arity version (with pre-loaded domain maps)
      domains_name = DomainCache.id_to_name_map()
      domains_external_id = DomainCache.id_to_external_id_map()
      context = context_for_fields(fields, :with_domain_external_id, domains_name, domains_external_id)

      context_with_lang = context |> Map.put("lang", "en")
  """

  def context_for_fields(fields, domain_type) do
    domains_name = DomainCache.id_to_name_map()
    domains_external_id = DomainCache.id_to_external_id_map()
    context_for_fields(fields, domain_type, domains_name, domains_external_id)
  end

  def context_for_fields(fields, domain_type, domains_name, domains_external_id) do
    Enum.reduce(fields, %{}, fn
      %{"type" => "domain"}, %{domains: %{}} = ctx ->
        ctx

      %{"type" => "domain"}, ctx ->
        {:ok, domains} = domain_content(domain_type, domains_name, domains_external_id)

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
    Map.new(content, fn {key, value} ->
      {key, Map.get(value, content_key, "")}
    end)
  end

  defp merge_with_content(content, template_content) do
    Map.new(content, fn {key, value} ->
      template_content
      |> Map.get(key)
      |> then(fn content_value -> {key, Map.put(content_value, "value", value)} end)
    end)
  end

  defp domain_content(:with_domain_name, domains_name, _domains_external_id), do: domains_name

  defp domain_content(:with_domain_external_id, _domains_name, domains_external_id),
    do: domains_external_id

  defp normalize_opts(opts) do
    case Keyword.get(opts, :locales) do
      nil ->
        Keyword.put_new_lazy(opts, :locales, fn -> I18nCache.get_active_locales!() end)

      _ ->
        opts
    end
    |> Keyword.put_new(:translations, false)
  end

  defp field_to_string(_field, nil, _ctx, _opts), do: {:plain, ""}

  defp field_to_string(
         %{"name" => name, "type" => "table", "values" => %{"table_columns" => colums}},
         content,
         _domain_map,
         opts
       ) do
    colums = Enum.map(colums, &Map.get(&1, "name"))
    xlsx = Keyword.get(opts, :xlsx, false)

    content
    |> get_field_value(name)
    |> value_to_list()
    |> Enum.map(fn row -> Enum.map(colums, &Map.get(row, &1, "")) end)
    |> case do
      [] ->
        {:plain, ""}

      [_ | _] = rows ->
        [colums | rows]
        |> Parser.Table.dump_to_iodata()
        |> IO.iodata_to_binary()
        |> String.replace_trailing("\n", "")
        |> then(&if xlsx, do: {:formatted, [&1, align_vertical: :top]}, else: {:plain, &1})
    end
  end

  defp field_to_string(
         %{"name" => name, "type" => "dynamic_table", "values" => %{"table_columns" => colums}},
         content,
         context,
         opts
       ) do
    headers = Enum.map(colums, &Map.get(&1, "name"))
    xlsx = Keyword.get(opts, :xlsx, false)

    content
    |> get_field_value(name)
    |> value_to_list()
    |> Enum.map(fn content -> fields_to_string([], colums, content, context, opts) end)
    |> then(fn
      [_ | _] = rows ->
        [headers | rows]
        |> Parser.Table.dump_to_iodata()
        |> IO.iodata_to_binary()
        |> String.replace_trailing("\n", "")
        |> then(&if xlsx, do: {:formatted, [&1, align_vertical: :top]}, else: {:plain, &1})

      [] ->
        {:plain, ""}
    end)
  end

  defp field_to_string(%{"name" => field_name} = field, content, domain_map, opts) do
    translatable = I18n.is_translatable_field?(field)
    translations = Keyword.get(opts, :translations, false)

    cond do
      field["type"] == "date" and opts[:xlsx] ->
        format_date_field(field, content, field_name, domain_map, opts)

      field["type"] == "datetime" and opts[:xlsx] ->
        format_datetime_field(field, content, field_name, domain_map, opts)

      translatable and translations ->
        string_fields =
          opts
          |> Keyword.get(:locales)
          |> Enum.map(&maybe_translatable_field_to_string(field, content, domain_map, &1, opts))

        {:plain, string_fields}

      true ->
        {:plain, maybe_translatable_field_to_string(field, content, domain_map, nil, opts)}
    end
  end

  defp format_date_field(field, content, field_name, domain_map, opts) do
    serial = FormatDateTime.get_excel_serial(content, field_name, :date)

    if serial do
      {:formatted,
       [
         {:excelts, serial},
         {:num_format, "dd-mm-yyyy"}
       ]}
    else
      {:plain, maybe_translatable_field_to_string(field, content, domain_map, nil, opts)}
    end
  end

  defp format_datetime_field(field, content, field_name, domain_map, opts) do
    serial = FormatDateTime.get_excel_serial(content, field_name, :datetime)

    if serial do
      {:formatted,
       [
         {:excelts, serial},
         {:num_format, "dd-mm-yyyy hh:MM:ss"}
       ]}
    else
      {:plain, maybe_translatable_field_to_string(field, content, domain_map, nil, opts)}
    end
  end

  defp maybe_translatable_field_to_string(
         %{"name" => name} = field,
         content,
         domain_map,
         locale,
         opts
       ) do
    translatable = I18n.is_translatable_field?(field)
    translations = Keyword.get(opts, :translations, false)

    default_locale = get_default_lang(Keyword.get(opts, :default_locale))
    lang = Keyword.get(opts, :lang, default_locale)

    name_with_locale =
      case {translations, translatable, default_locale} do
        {true, true, default_locale} when default_locale != locale ->
          "#{name}_#{locale}"

        {false, true, default_locale} when default_locale != lang ->
          "#{name}_#{lang}"

        _ ->
          name
      end

    content
    |> get_field_value(name, name_with_locale)
    |> value_to_list()
    |> Enum.map(&parse_field(field, &1, domain_map))
    |> Enum.reject(&is_nil/1)
    |> Enum.join("|")
  end

  defp get_field_value(content, name, name_with_locale) do
    field =
      Map.get(content, name_with_locale) || Map.get(content, String.to_atom(name_with_locale)) ||
        Map.get(content, name) || Map.get(content, String.to_atom(name))

    case field do
      %{"value" => value} -> value
      value when not is_map(value) -> value
    end
  end

  defp get_field_value(content, name) do
    field = Map.get(content, name) || Map.get(content, String.to_atom(name))

    case field do
      %{"value" => value} -> value
      value when not is_map(value) -> value
    end
  end

  defp parse_field(%{"type" => "url"}, %{url_name: "", url_value: url_value}, _ctx),
    do: url_value

  defp parse_field(%{"type" => "url"}, %{"url_name" => "", "url_value" => url_value}, _ctx),
    do: url_value

  defp parse_field(%{"type" => "url"}, %{url_name: url_name, url_value: url_value}, _ctx),
    do: "[#{url_name}] (#{url_value})"

  defp parse_field(%{"type" => "url"}, %{"url_name" => url_name, "url_value" => url_value}, _ctx),
    do: "[#{url_name}] (#{url_value})"

  defp parse_field(%{"type" => "url"}, %{url_value: url_value}, _ctx), do: url_value
  defp parse_field(%{"type" => "url"}, %{"url_value" => url_value}, _ctx), do: url_value
  defp parse_field(%{"type" => "url"}, _, _ctx), do: nil

  defp parse_field(%{"type" => "domain"}, value, %{domains: domains}), do: Map.get(domains, value)

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
             I18nCache.get_definition(lang, "fields." <> label <> "." <> text,
               default_value: text
             )

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

  defp fields_to_string(acc, fields, content, ctx, opts) do
    Enum.reduce(
      fields,
      acc,
      fn field, acc ->
        case field_to_string(field, content, ctx, opts) do
          {:formatted, list} ->
            acc ++ [list]

          {:plain, string} ->
            acc ++ List.flatten([string])
        end
      end
    )
  end

  defp value_to_list(nil), do: []
  defp value_to_list([""]), do: []
  defp value_to_list(""), do: []
  defp value_to_list(content) when is_list(content), do: content
  defp value_to_list(content), do: [content]

  def get_default_lang(nil) do
    {:ok, lang} = I18nCache.get_default_locale()
    lang
  end

  def get_default_lang(lang), do: lang
end
