defmodule TdDfLib.Validation do
  @moduledoc """
  Template content validation support.
  """

  alias Ecto.Changeset
  alias TdDfLib.Format
  alias TdDfLib.Templates

  @types %{
    "string" => :string,
    "boolean" => :boolean,
    "url" => :map,
    "user" => :string,
    "enriched_text" => :map,
    "table" => :map,
    "integer" => :integer,
    "float" => :float,
    "system" => :map,
    "copy" => :string,
    "domain" => :map
  }

  def build_changeset(content, content_schema, opts \\ []) do
    changeset_fields = get_changeset_fields(content_schema)

    {content, changeset_fields}
    |> Changeset.cast(content, Map.keys(changeset_fields))
    |> add_content_validation(content_schema, opts)
  end

  defp get_changeset_fields(content_schema) do
    item_mapping = fn item ->
      name = Map.get(item, "name")
      type = Map.get(@types, Map.get(item, "type"), :string)
      cardinality = Map.get(item, "cardinality")
      {String.to_atom(name), get_field_type(type, cardinality)}
    end

    Map.new(content_schema, item_mapping)
  end

  defp get_field_type(type, "*"), do: {:array, type}
  defp get_field_type(type, "+"), do: {:array, type}
  defp get_field_type(type, _), do: type

  # Filters schema for non applicable dependant field
  defp add_content_validation(
         changeset,
         %{"depends" => %{"on" => on, "to_be" => to_be}} = field_spec,
         opts
       ) do
    dependent_value = Changeset.get_field(changeset, on)

    if Enum.member?(to_be, dependent_value) do
      add_content_validation(changeset, Map.drop(field_spec, ["depends"]), opts)
    else
      changeset
    end
  end

  defp add_content_validation(changeset, %{} = field_spec, opts) do
    changeset
    |> add_require_validation(field_spec)
    |> add_inclusion_validation(field_spec, opts)
    |> add_image_validation(field_spec)
  end

  defp add_content_validation(changeset, [tail | head], opts) do
    changeset
    |> add_content_validation(tail, opts)
    |> add_content_validation(head, opts)
  end

  defp add_content_validation(changeset, [], _opts), do: changeset

  defp add_require_validation(changeset, %{"name" => name, "cardinality" => "1"}) do
    validate_single(name, changeset)
  end

  defp add_require_validation(changeset, %{"name" => name, "cardinality" => "+"}) do
    validate_multiple(name, changeset)
  end

  defp add_require_validation(
         changeset,
         %{"mandatory" => %{"on" => on, "to_be" => target = [_ | _]}} = field
       ) do
    dependent = Changeset.get_field(changeset, on)

    if Templates.meets_dependency?(dependent, target) do
      validate_required_field(changeset, field)
    else
      changeset
    end
  end

  defp add_require_validation(changeset, %{}), do: changeset

  defp add_inclusion_validation(
         changeset,
         %{
           "name" => name,
           "values" => %{"fixed" => fixed}
         },
         _opts
       ) do
    validate_inclusion(changeset, name, fixed)
  end

  defp add_inclusion_validation(
         changeset,
         %{
           "name" => name,
           "values" => %{"fixed_tuple" => fixed_tuple}
         },
         _opts
       ) do
    fixed = Enum.map(fixed_tuple, &Map.get(&1, "value"))
    validate_inclusion(changeset, name, fixed)
  end

  defp add_inclusion_validation(
         changeset,
         %{
           "name" => name,
           "values" => %{"domain" => domain_values = %{}}
         },
         opts
       ) do
    field = String.to_atom(name)

    case take_domain_values(domain_values, opts[:domain_id], opts[:domain_ids]) do
      [_ | _] = available -> validate_inclusion(changeset, name, available)
      _ -> Changeset.delete_change(changeset, field)
    end
  end

  defp add_inclusion_validation(changeset, %{}, _opts), do: changeset

  defp take_domain_values(%{} = _domain_values, nil, nil), do: :none

  defp take_domain_values(%{} = domain_values, nil, domain_ids) do
    keys = Enum.map(domain_ids, &Format.to_string_format/1)

    domain_values
    |> Map.take(keys)
    |> Map.values()
    |> Enum.flat_map(& &1)
    |> Enum.uniq()
  end

  defp take_domain_values(%{} = domain_values, domain_id, domain_ids) do
    take_domain_values(domain_values, nil, [domain_id | List.wrap(domain_ids)])
  end

  defp add_image_validation(changeset, %{"name" => name, "type" => "image"}) do
    field = String.to_atom(name)
    Changeset.validate_change(changeset, field, &image_validation/2)
  end

  defp add_image_validation(changeset, %{}), do: changeset

  defp validate_no_empty_items(field, [_h | _t] = values) do
    case Enum.any?([nil, "", []], &Enum.member?(values, &1)) do
      true -> Keyword.new([{field, "should not contain empty values"}])
      _ -> []
    end
  end

  defp validate_no_empty_items(field, %{} = values) do
    case values == %{} do
      true -> Keyword.new([{field, "map should not be empty"}])
      _ -> []
    end
  end

  defp validate_no_empty_items(_, _), do: []

  defp image_validation(_field, nil), do: []

  defp image_validation(field, image_data) do
    {start, _length} = :binary.match(image_data, ";base64,")
    type = :binary.part(image_data, 0, start)

    case Regex.match?(~r/(jpg|jpeg|png|gif)/, type) do
      true -> []
      _ -> Keyword.new([{field, "invalid image type"}])
    end
  end

  defp validate_required_field(changeset, %{"name" => name, "cardinality" => "*"}) do
    validate_multiple(name, changeset)
  end

  defp validate_required_field(changeset, %{"name" => name, "cardinality" => "?"}) do
    validate_single(name, changeset)
  end

  defp validate_required_field(changeset, _field), do: changeset

  defp validate_multiple(name, changeset) do
    field = String.to_atom(name)

    changeset
    |> Changeset.validate_required(field)
    |> Changeset.validate_length(field, min: 1)
    |> Changeset.validate_change(field, &validate_no_empty_items/2)
  end

  defp validate_single(name, changeset) do
    field = String.to_atom(name)

    changeset
    |> Changeset.validate_required(field)
    |> Changeset.validate_change(field, &validate_no_empty_items/2)
  end

  defp validate_inclusion(%{data: data} = changeset, name, items) do
    field = String.to_atom(name)

    case Map.get(data, name) do
      l when is_list(l) -> Changeset.validate_subset(changeset, field, items)
      _not_list -> Changeset.validate_inclusion(changeset, field, items)
    end
  end

  @doc """
  Returns a 2-arity validator function that can be used by
  `Ecto.Changeset.validate_change/3` on a dynamic content field. The argument
  may be either the name of a template or it's flattened schema, as returned by
  `Templates.content_schema/1`.
  """
  def validator(template_or_schema, opts \\ [])

  def validator({:error, reason}, _opts) do
    fn field, _value ->
      [{field, {"invalid template", [reason: reason]}}]
    end
  end

  def validator(template, opts) when is_binary(template) do
    template
    |> Templates.content_schema()
    |> validator(opts)
  end

  def validator(schema, opts) when is_list(schema) do
    fn field, value ->
      case build_changeset(value, schema, opts) do
        %{valid?: false, errors: errors} -> [{field, {"invalid content", errors}}]
        _ -> []
      end
    end
  end
end
