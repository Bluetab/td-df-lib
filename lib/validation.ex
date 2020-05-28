defmodule TdDfLib.Validation do
  @moduledoc """
  Template content validation support.
  """

  alias Ecto.Changeset
  alias TdDfLib.Templates

  @types %{
    "string" => :string,
    "boolean" => :boolean,
    "url" => :map,
    "user" => :string,
    "enriched_text" => :map,
    "table" => :map
  }

  def build_changeset(content, content_schema) do
    changeset_fields = get_changeset_fields(content_schema)

    {content, changeset_fields}
    |> Changeset.cast(content, Map.keys(changeset_fields))
    |> add_content_validation(content_schema)
  end

  defp get_changeset_fields(content_schema) do
    item_mapping = fn item ->
      name = item |> Map.get("name")
      type = Map.get(@types, Map.get(item, "type"), :string)
      cardinality = item |> Map.get("cardinality")
      {String.to_atom(name), get_field_type(type, cardinality)}
    end

    content_schema
    |> Enum.map(item_mapping)
    |> Map.new()
  end

  defp get_field_type(type, "*"), do: {:array, type}
  defp get_field_type(type, "+"), do: {:array, type}
  defp get_field_type(type, _), do: type

  # Filters schema for non applicable dependant field
  defp add_content_validation(
         changeset,
         %{"depends" => %{"on" => depend_on, "to_be" => depend_to_be}} = content_item
       ) do
    dependent_value = Changeset.get_field(changeset, depend_on)

    if Enum.member?(depend_to_be, dependent_value) do
      add_content_validation(changeset, Map.drop(content_item, ["depends"]))
    else
      changeset
    end
  end

  defp add_content_validation(changeset, %{} = content_item) do
    changeset
    |> add_require_validation(content_item)
    |> add_inclusion_validation(content_item)
  end

  defp add_content_validation(changeset, [tail | head]) do
    changeset
    |> add_content_validation(tail)
    |> add_content_validation(head)
  end

  defp add_content_validation(changeset, []), do: changeset

  defp add_require_validation(changeset, %{"name" => name, "cardinality" => "1"}) do
    field = String.to_atom(name)

    changeset
    |> Changeset.validate_required(field)
    |> Changeset.validate_change(field, &validate_no_empty_items/2)
  end

  defp add_require_validation(changeset, %{"name" => name, "cardinality" => "+"}) do
    field = String.to_atom(name)

    changeset
    |> Changeset.validate_required(field)
    |> Changeset.validate_length(field, min: 1)
    |> Changeset.validate_change(field, &validate_no_empty_items/2)
  end

  defp add_require_validation(changeset, %{}), do: changeset

  defp add_inclusion_validation(changeset, %{"name" => name, "values" => %{"fixed" => fixed}}) do
    field = String.to_atom(name)

    value =
      changeset
      |> Map.get(:data)
      |> Map.get(name)

    case is_list(value) do
      true ->
        Changeset.validate_subset(changeset, field, fixed)

      _ ->
        Changeset.validate_inclusion(changeset, field, fixed)
    end
  end

  defp add_inclusion_validation(changeset, %{}), do: changeset

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

  @doc """
  Returns a 2-arity validator function that can be used by
  `Ecto.Changeset.validate_change/3` on a dynamic content field. The argument
  may be either the name of a template or it's flattened schema, as returned by
  `Templates.content_schema/1`.
  """
  def validator(template_or_schema)

  def validator({:error, reason}) do
    fn field, _value ->
      [{field, {"invalid template", [reason: reason]}}]
    end
  end

  def validator(template) when is_binary(template) do
    template
    |> Templates.content_schema()
    |> validator()
  end

  def validator(schema) when is_list(schema) do
    fn field, value ->
      case build_changeset(value, schema) do
        %{valid?: false, errors: errors} -> [{field, {"invalid content", errors}}]
        _ -> []
      end
    end
  end
end
