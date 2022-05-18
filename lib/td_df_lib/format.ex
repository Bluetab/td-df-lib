defmodule TdDfLib.Format do
  @moduledoc """
  Manages content formatting
  """
  alias TdCache.SystemCache
  alias TdCache.TaxonomyCache
  alias TdDfLib.RichText
  alias TdDfLib.Templates

  @cached ["domain", "system"]
  @format_types ["domain", "enriched_text", "system"]

  def apply_template(content, fields, opts \\ [])

  def apply_template(nil, _, _opts), do: %{}

  def apply_template(_, nil, _opts), do: %{}

  def apply_template(%{} = content, fields, opts) do
    content
    |> default_values(fields, opts)
    |> cached_values(fields)
  end

  def maybe_put_identifier_by_id(changeset_content, old_content, template_id)
      when is_number(template_id) do
    Templates.content_schema_by_id(template_id)
    |> maybe_put_identifier_template(changeset_content, old_content)
  end

  def maybe_put_identifier_by_id(changeset_content, _old_content, _template_id),
    do: changeset_content

  def maybe_put_identifier(changeset_content, old_content, template) when is_binary(template) do
    Templates.content_schema(template)
    |> maybe_put_identifier_template(changeset_content, old_content)
  end

  def maybe_put_identifier(_, content, _), do: content

  def maybe_put_identifier_template(
        {:error, :template_not_found},
        changeset_content,
        _old_content
      ) do
    changeset_content
  end

  def maybe_put_identifier_template(fields, nil, old_content) do
    maybe_put_identifier_template(fields, %{}, old_content)
  end

  def maybe_put_identifier_template(fields, changeset_content, old_content)
      when is_list(fields) do
    fields
    |> get_identifier_name()
    |> maybe_put_identifier_idname(changeset_content, old_content)
  end

  def get_identifier_name(fields) do
    Enum.find(
      fields,
      &has_identifier_widget?/1
    )
    |> identifier_name_aux()
  end

  def identifier_name_aux(%{"name" => identifier_name} = _identifier_field) do
    identifier_name
  end

  def identifier_name_aux(nil), do: nil

  def maybe_put_identifier_idname(identifier_name, changeset_content, nil = _old_content) do
    maybe_put_identifier_idname(identifier_name, changeset_content, %{})
  end

  def maybe_put_identifier_idname(nil, changeset_content, _old_content) do
    changeset_content
  end

  def maybe_put_identifier_idname(
        identifier_name,
        changeset_content,
        old_content
      ) do
    Map.put(
      changeset_content,
      identifier_name,
      get_identifier_value(Map.get(old_content, identifier_name))
    )
  end

  defp get_identifier_value(""), do: get_identifier_value(nil)

  defp get_identifier_value(identifier_value) when not is_nil(identifier_value),
    do: identifier_value

  defp get_identifier_value(_), do: Ecto.UUID.generate()

  def has_identifier_widget?(%{"widget" => "identifier"}), do: true
  def has_identifier_widget?(_), do: false

  def enrich_content_values(%{} = content, %{content: fields}) do
    fields = flatten_content_fields(fields)
    cached_values(content, fields)
  end

  def enrich_content_values(content, _), do: content

  def search_values(content, fields, opts \\ [])

  def search_values(%{} = content, %{content: fields}, opts) do
    fields = flatten_content_fields(fields)

    content
    |> apply_template(fields, opts)
    |> drop_values(fields)
    |> format_search_values(fields)
  end

  def search_values(_, _, _), do: nil

  def flatten_content_fields(content) do
    Enum.flat_map(content, fn %{"name" => group, "fields" => fields} ->
      Enum.map(fields, &Map.put(&1, "group", group))
    end)
  end

  defp cached_values(content, fields) do
    keys = Map.keys(content)

    fields =
      Enum.filter(fields, fn
        %{"type" => type, "name" => name} -> type in @cached and name in keys
        _ -> false
      end)

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
      |> Enum.filter(&(Map.get(&1, "type") in ["image", "copy"]))
      |> Enum.map(&Map.get(&1, "name"))

    Map.drop(content, keys)
  end

  def format_search_values(content, fields) do
    fields =
      Enum.filter(fields, fn
        %{"type" => type} -> type in @format_types
        _ -> false
      end)

    field_names = Enum.map(fields, &Map.get(&1, "name"))

    search_values =
      content
      |> Map.take(field_names)
      |> set_search_values(fields)

    Map.merge(content, search_values)
  end

  defp default_values(content, fields, opts) do
    field_names = Enum.map(fields, &Map.get(&1, "name"))

    content
    |> Map.take(field_names)
    |> set_default_values(fields, opts)
  end

  def set_default_values(content, fields, opts \\ []) do
    Enum.reduce(fields, content, &set_default_value(&2, &1, opts))
  end

  def set_search_values(content, fields) do
    Enum.reduce(fields, content, &set_search_value(&1, &2))
  end

  defp set_search_value(%{"name" => name, "type" => "enriched_text"}, acc) do
    Map.put(acc, name, RichText.to_plain_text(Map.get(acc, name)))
  end

  defp set_search_value(%{"name" => name, "type" => type}, acc) when type in @cached do
    case Map.get(acc, name) do
      value = %{} -> Map.put(acc, name, [value])
      value -> Map.put(acc, name, value)
    end
  end

  defp set_search_value(_field, acc), do: acc

  def set_default_value(content, field, opts \\ [])

  def set_default_value(content, %{"depends" => %{"on" => on, "to_be" => to_be}} = field, opts) do
    dependent_value = Map.get(content, on)

    if Enum.member?(to_be, dependent_value) do
      set_default_value(content, Map.delete(field, "depends"), opts)
    else
      content
    end
  end

  def set_default_value(
        content,
        %{"name" => name, "default" => default = %{}, "values" => %{"switch" => %{"on" => on}}} =
          field,
        opts
      ) do
    dependent_value = Map.get(content, on)
    default_value = Map.get(default, dependent_value)

    case default_value do
      nil ->
        field = Map.delete(field, "default")
        set_default_value(content, field, opts)

      default_value ->
        Map.put_new(content, name, default_value)
    end
  end

  def set_default_value(
        content,
        %{"name" => name, "default" => default = %{}, "values" => values} = field,
        opts
      )
      when is_map_key(values, "domain") do
    domain_ids = domain_ids(opts)
    default_value = take_first_value(default, domain_ids)

    case default_value do
      nil ->
        field = Map.delete(field, "default")
        set_default_value(content, field, opts)

      default_value ->
        Map.put_new(content, name, default_value)
    end
  end

  def set_default_value(content, %{"name" => name, "default" => default}, _opts) do
    Map.put_new(content, name, default)
  end

  def set_default_value(
        content,
        %{"name" => name, "cardinality" => "*", "values" => values},
        _opts
      )
      when not is_nil(values) do
    Map.put_new(content, name, [""])
  end

  def set_default_value(
        content,
        %{"name" => name, "cardinality" => "+", "values" => values},
        _opts
      )
      when not is_nil(values) do
    Map.put_new(content, name, [""])
  end

  def set_default_value(content, %{"name" => name, "values" => values}, _opts)
      when not is_nil(values) do
    Map.put_new(content, name, "")
  end

  def set_default_value(content, %{}, _opts), do: content

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

  def format_field(%{"content" => content, "type" => type, "cardinality" => cardinality})
      when cardinality in ["+", "*"] and is_binary(content) and type !== "user" do
    content
    |> String.split("|", trim: true)
    |> Enum.map(fn c -> format_field(%{"content" => c, "type" => type}) end)
    |> List.flatten()
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

  def format_field(%{"content" => content}), do: content

  defp set_cached_values(content, fields) do
    Enum.reduce(fields, content, &set_cached_value(&1, &2))
  end

  defp set_cached_value(%{"name" => name, "type" => "system", "cardinality" => cardinality}, acc) do
    Map.put(acc, name, format_system(Map.get(acc, name), cardinality))
  end

  defp set_cached_value(%{"name" => name, "type" => "domain", "cardinality" => cardinality}, acc) do
    Map.put(acc, name, format_domain(Map.get(acc, name), cardinality))
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
    case SystemCache.get_by_external_id(external_id) do
      {:ok, system} -> apply_cardinality(system, cardinality)
      _ -> nil
    end
  end

  defp format_system(system, _cardinality), do: system

  defp format_domain(%{"id" => id} = domain, _cardinality) when not is_nil(id) do
    case TaxonomyCache.get_domain(id) do
      nil -> domain
      domain -> domain
    end
  end

  defp format_domain([_ | _] = domains, cardinality) do
    Enum.map(domains, &format_domain(&1, cardinality))
  end

  defp format_domain("", _cardinality), do: nil

  defp format_domain(external_id, cardinality) when is_binary(external_id) do
    external_id
    |> TaxonomyCache.get_by_external_id()
    |> apply_cardinality(cardinality)
  end

  defp format_domain(domain, _cardinality), do: domain

  defp apply_cardinality(value = %{}, cardinality) when cardinality in ["*", "+"], do: [value]

  defp apply_cardinality(value, _cardinality), do: value

  defp domain_ids(opts) do
    opts
    |> Keyword.take([:domain_id, :domain_ids])
    |> Keyword.values()
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.map(&to_string_format/1)
  end

  defp take_first_value(map, keys) do
    map
    |> Map.take(keys)
    |> Map.values()
    |> Enum.at(0)
  end

  def to_string_format(id) when is_number(id), do: Integer.to_string(id)

  def to_string_format(id), do: id
end
