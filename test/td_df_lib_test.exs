defmodule TdDfLibTest do
  use ExUnit.Case
  doctest TdDfLib

  alias TdDfLib.Validation
  @df_cache Application.get_env(:td_df_lib, :df_cache)

  setup_all do
    start_supervised(@df_cache)
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

  # Test field value type
  def get_changeset_for(field_type, field_value, cardinality) do
    @df_cache.put_template(%{
        id: 0, label: "label", name: "test_name",
        content: [%{
          "name" => "field",
          "type" => field_type,
          "cardinality" => cardinality
        }]
    })
    content = %{"field" => field_value}
    Validation.get_content_changeset(content, "test_name")
  end

  test "valid type string cardinality 1" do
    changeset = get_changeset_for("string", "string_value", "1")
    assert changeset.valid?
  end

  test "valid type string cardinality ?" do
    changeset = get_changeset_for("string", "string_value", "?")
    assert changeset.valid?
  end

  test "invalid type string cardinality 1" do
    changeset = get_changeset_for("string", ["string_value"], "1")
    refute changeset.valid?
  end

  test "invalid type string cardinality ?" do
    changeset = get_changeset_for("string", ["string_value"], "?")
    refute changeset.valid?
  end

  test "valid type string cardinality +" do
    changeset = get_changeset_for("string", ["string_value"], "+")
    assert changeset.valid?
  end

  test "valid type string cardinality *" do
    changeset = get_changeset_for("string", ["string_value"], "*")
    assert changeset.valid?
  end

  test "invalid type string cardinality +" do
    changeset = get_changeset_for("string", "string_value", "+")
    refute changeset.valid?
  end

  test "invalid type string cardinality *" do
    changeset = get_changeset_for("string", "string_value", "*")
    refute changeset.valid?
  end

  test "valid type url" do
    changeset = get_changeset_for("url", %{}, "?")
    assert changeset.valid?
  end

  test "invalid type url" do
    changeset = get_changeset_for("url", "string_value", "?")
    refute changeset.valid?
  end

  test "invalid required type string cardinality 1" do
    changeset = get_changeset_for("string", "", "1")
    refute changeset.valid?
    changeset = get_changeset_for("string", nil, "1")
    refute changeset.valid?
  end

  test "valid not required type string cardinality ?" do
    changeset = get_changeset_for("string", "", "?")
    assert changeset.valid?
    changeset = get_changeset_for("string", nil, "?")
    assert changeset.valid?
  end

  test "invalid required type string cardinality +" do
    changeset = get_changeset_for("string", [], "+")
    refute changeset.valid?
    changeset = get_changeset_for("string", nil, "+")
    refute changeset.valid?
  end

  test "valid not required type string cardinality *" do
    changeset = get_changeset_for("string", [], "*")
    assert changeset.valid?
    changeset = get_changeset_for("string", nil, "*")
    assert changeset.valid?
  end

  test "invalid content for string cardinality *" do
    changeset = get_changeset_for("string", ["valid", 123], "*")
    refute changeset.valid?
  end

  # @string -> :string
  test "string field is valid with string value" do
    changeset = get_changeset_for("string", "string", "1")
    assert changeset.valid?
  end
  test "string field is invalid with integer value" do
    changeset = get_changeset_for("string", 123, "1")
    refute changeset.valid?
  end

  test "content with hidden required field returns valid changeset" do
    @df_cache.put_template(%{
      id: 0,
      label: "label",
      name: "test_name",
      content: [
        %{
          "name" => "radio_list",
          "type" => "string",
          "cardinality" => "1",
          "values" => ["Yes", "No"]
        },
        %{
          "name" => "dependant_text",
          "type" => "string",
          "cardinality" => "1",
          "depends" => %{"on" => "radio_list", "to_be" => "Yes"}
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
      content: [
        %{
          "name" => "radio_list",
          "type" => "string",
          "cardinality" => "1",
          "values" => ["Yes", "No"]
        },
        %{
          "name" => "dependant_text",
          "type" => "string",
          "cardinality" => "1",
          "depends" => %{"on" => "radio_list", "to_be" => "Yes"}
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
      content: [
        %{
          "name" => "radio_list",
          "type" => "string",
          "cardinality" => "1",
          "values" => ["Yes", "No"]
        },
        %{
          "name" => "dependant_text",
          "type" => "string",
          "cardinality" => "1",
          "depends" => %{"on" => "radio_list", "to_be" => "Yes"}
        }]
    })

    content = %{"radio_list" => "Yes", "dependant_text" => "value"}
    changeset = Validation.get_content_changeset(content, "test_name")
    assert changeset.valid?
  end
end
