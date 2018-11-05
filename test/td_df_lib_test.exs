defmodule TdDfLibTest do
  use ExUnit.Case
  doctest TdDfLib

  alias TdPerms.DynamicFormCache
  alias TdDfLib.Validation

  test "greets the world" do
    assert TdDfLib.hello() == :world
  end

  test "empty content on empty template return valid changeset" do
    DynamicFormCache.put_template_content(%{
        name: "test_name",
        content: []
    })
    changeset = Validation.get_content_changeset(%{}, "test_name")
    assert changeset.valid?
  end

  test "empty content on required field return invalid changeset" do
    DynamicFormCache.put_template_content(%{
        name: "test_name",
        content: [%{
          name: "field",
          type: "string",
          required: true
        }]
    })
    changeset = Validation.get_content_changeset(%{}, "test_name")
    refute changeset.valid?
  end

  test "non empty content on required field returns valid changeset" do
    DynamicFormCache.put_template_content(%{
        name: "test_name",
        content: [%{
          name: "field",
          type: "string",
          required: true
        }]
    })
    changeset = Validation.get_content_changeset(%{"field" => "value"}, "test_name")
    assert changeset.valid?
  end
end
