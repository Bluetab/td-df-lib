defmodule TdDfLibTest do
  use ExUnit.Case
  doctest TdDfLib

  alias TdDfLib.Validation
  @df_cache Application.get_env(:td_df_lib, :df_cache)

  setup_all do
    start_supervised @df_cache
    :ok
  end

  test "empty content on empty template return valid changeset" do
    @df_cache.put_template(%{
        id: 0,
        label: "label",
        name: "test_name",
        content: []
    })
    changeset = Validation.get_content_changeset(%{}, "test_name")
    assert changeset.valid?
  end

  test "empty content on required field return invalid changeset" do
    @df_cache.put_template(%{
        id: 0,
        label: "label",
        name: "test_name",
        content: [%{
          "name" => "field",
          "type" => "string",
          "required" => true
        }]
    })
    changeset = Validation.get_content_changeset(%{}, "test_name")
    refute changeset.valid?
  end

  # Test field value type
  def get_changeset_for(field_type, field_value) do
    @df_cache.put_template(%{
        id: 0, label: "label", name: "test_name",
        content: [%{"name" => "field", "type" => field_type}]
    })
    content = %{"field" => field_value}
    Validation.get_content_changeset(content, "test_name")
  end
  # @string -> :string
  test "string field is valid with string value" do
    changeset = get_changeset_for("string", "string")
    assert changeset.valid?
  end
  test "string field is invalid with integer value" do
    changeset = get_changeset_for("string", 123)
    refute changeset.valid?
  end

  # @list -> :string
  test "list field is valid with string value" do
    changeset = get_changeset_for("list", "string")
    assert changeset.valid?
  end
  test "list field is invalid with integer value" do
    changeset = get_changeset_for("list", 123)
    refute changeset.valid?
  end

  # @variable_list -> {:array, :string}
  test "variable_list field is valid with string array value" do
    changeset = get_changeset_for("variable_list", ["string", "array"])
    assert changeset.valid?
  end
  test "variable_list field is invalid with integer array value" do
    changeset = get_changeset_for("variable_list", [123, 456, "string"])
    refute changeset.valid?
  end
  test "variable_list field is invalid with integer value" do
    changeset = get_changeset_for("variable_list", 123)
    refute changeset.valid?
  end

  # @variable_map_list -> {:array, :map}
  test "variable_map_list field is valid with map array value" do
    changeset = get_changeset_for("variable_map_list", [%{}, %{}])
    assert changeset.valid?
  end
  test "livariable_map_listst field is invalid with integer array value" do
    changeset = get_changeset_for("variable_map_list", [123, 456])
    refute changeset.valid?
  end
  test "livariable_map_listst field is invalid with integer value" do
    changeset = get_changeset_for("variable_map_list", 123)
    refute changeset.valid?
  end

  # @map_list -> :map
  test "map_list field is valid with map value" do
    changeset = get_changeset_for("map_list", %{})
    assert changeset.valid?
  end
  test "map_list field is invalid with string value" do
    changeset = get_changeset_for("map_list", "string")
    refute changeset.valid?
  end

  test "non empty content on required field returns valid changeset" do
    @df_cache.put_template(%{
        id: 0,
        label: "label",
        name: "test_name",
        content: [%{
          "name" => "field",
          "type" => "string",
          "required" => true
        }]
    })
    changeset = Validation.get_content_changeset(%{"field" => "value"}, "test_name")
    assert changeset.valid?
  end

  test "content with hidden required field returns valid changeset" do
    @df_cache.put_template(%{
        id: 0,
        label: "label",
        name: "test_name",
        content: [%{
          "name" => "radio_list",
          "type" => "list",
          "required" => true,
          "values" => ["Yes", "No"]
        }, %{
          "name" => "dependant_text",
          "type" => "string",
          "required" => true,
          "depends" => %{ "on" => "radio_list", "to_be" => "Yes" }
        }]
    })
    changeset = Validation.get_content_changeset(%{"radio_list" => "No"}, "test_name")
    assert changeset.valid?
  end

  test "content with depend required not set field returns invalid changeset" do
    @df_cache.put_template(%{
        id: 0,
        label: "label",
        name: "test_name",
        content: [%{
          "name" => "radio_list",
          "type" => "list",
          "required" => true,
          "values" => ["Yes", "No"]
        }, %{
          "name" => "dependant_text",
          "type" => "string",
          "required" => true,
          "depends" => %{ "on" => "radio_list", "to_be" => "Yes" }
        }]
    })
    changeset = Validation.get_content_changeset(%{"radio_list" => "Yes"}, "test_name")
    refute changeset.valid?
  end

  test "content with depend required set field returns valid changeset" do
    @df_cache.put_template(%{
        id: 0,
        label: "label",
        name: "test_name",
        content: [%{
          "name" => "radio_list",
          "type" => "list",
          "required" => true,
          "values" => ["Yes", "No"]
        }, %{
          "name" => "dependant_text",
          "type" => "string",
          "required" => true,
          "depends" => %{ "on" => "radio_list", "to_be" => "Yes" }
        }]
    })
    content = %{"radio_list" => "Yes", "dependant_text" => "value"}
    changeset = Validation.get_content_changeset(content, "test_name")
    assert changeset.valid?
  end
end
