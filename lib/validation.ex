defmodule TdDfLib.Validation do
  @moduledoc """
  The Template Validation.
  """

  alias Ecto.Changeset
  alias TdPerms.DynamicFormCache

  @string "string"
  @list "list"
  @variable_list "variable_list"
  @variable_map_list "variable_map_list"

  def get_content_changeset(content, template_name) do
    schema = get_template_cotent(template_name)
    build_changeset(content, schema)
  end

  defp get_template_cotent(template_name) do
    DynamicFormCache.get_template_content(template_name)
  end

  def build_changeset(content, content_schema) do
    changeset_fields = get_changeset_fields(content_schema)
    changeset = {content, changeset_fields}
    changeset
      |> Changeset.cast(content, Map.keys(changeset_fields))
      |> add_content_validation(content_schema)
  end

  defp get_changeset_fields(content_schema) do
    item_mapping = fn item ->
      name = item |> Map.get("name")
      type = item |> Map.get("type")
      {String.to_atom(name), get_changeset_field(type)}
    end

    content_schema
    |> Enum.map(item_mapping)
    |> Map.new()
  end

  defp get_changeset_field(type) do
    case type do
      @string -> :string
      @list -> :string
      @variable_list -> {:array, :string}
      @variable_map_list -> {:array, :map}
    end
  end

  defp add_content_validation(changeset, %{} = content_item) do
    changeset
    |> add_require_validation(content_item)
    |> add_max_length_validation(content_item)
    |> add_inclusion_validation(content_item)
  end

  defp add_content_validation(changeset, [tail | head]) do
    changeset
    |> add_content_validation(tail)
    |> add_content_validation(head)
  end

  defp add_content_validation(changeset, []), do: changeset

  defp add_require_validation(changeset, %{"name" => name, "required" => true}) do
    Changeset.validate_required(changeset, [String.to_atom(name)])
  end

  defp add_require_validation(changeset, %{}), do: changeset

  defp add_max_length_validation(changeset, %{"name" => name, "max_size" => max_size}) do
    Changeset.validate_length(changeset, String.to_atom(name), max: max_size)
  end

  defp add_max_length_validation(changeset, %{}), do: changeset

  defp add_inclusion_validation(changeset,
    %{"type" => "list", "meta" => %{"role" => _rolename}}), do: changeset
  defp add_inclusion_validation(changeset, %{"name" => name, "type" => "list", "values" => values}) do
    Changeset.validate_inclusion(changeset, String.to_atom(name), values)
  end

  defp add_inclusion_validation(changeset, %{}), do: changeset


end
