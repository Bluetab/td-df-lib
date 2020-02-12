defmodule TdDfLibTest do
  use ExUnit.Case

  alias TdCache.TemplateCache
  alias TdDfLib.Validation

  setup_all do
    start_supervised(TdCache.TemplateCache)
    :ok
  end

  setup do
    template = random_template()

    on_exit(fn ->
      TemplateCache.delete(template.id)
    end)

    {:ok, template: template}
  end

  test "empty content on empty template return valid changeset", %{template: template} do
    template =
      template
      |> Map.put(:content, [])

    TemplateCache.put(template)

    {:ok, schema} = TemplateCache.get(template.id, :content)
    changeset = Validation.build_changeset(%{}, schema)
    assert changeset.valid?
  end

  # Test field value type
  def get_changeset_for(field_type, field_value, cardinality, template) do
    template
    |> Map.put(:content, [
      %{
        "name" => "field",
        "type" => field_type,
        "cardinality" => cardinality
      }
    ])
    |> TemplateCache.put()

    content = %{"field" => field_value}
    {:ok, schema} = TemplateCache.get(template.id, :content)
    Validation.build_changeset(content, schema)
  end

  test "valid type string cardinality 1", %{template: template} do
    changeset = get_changeset_for("string", "string_value", "1", template)
    assert changeset.valid?
  end

  test "valid type string cardinality ?", %{template: template} do
    changeset = get_changeset_for("string", "string_value", "?", template)
    assert changeset.valid?
  end

  test "invalid type string cardinality 1", %{template: template} do
    changeset = get_changeset_for("string", ["string_value"], "1", template)
    refute changeset.valid?
  end

  test "invalid type string cardinality ?", %{template: template} do
    changeset = get_changeset_for("string", ["string_value"], "?", template)
    refute changeset.valid?
  end

  test "valid type string cardinality +", %{template: template} do
    changeset = get_changeset_for("string", ["string_value"], "+", template)
    assert changeset.valid?
  end

  test "valid type string cardinality *", %{template: template} do
    changeset = get_changeset_for("string", ["string_value"], "*", template)
    assert changeset.valid?
  end

  test "invalid type string cardinality +", %{template: template} do
    changeset = get_changeset_for("string", "string_value", "+", template)
    refute changeset.valid?
  end

  test "invalid type string cardinality *", %{template: template} do
    changeset = get_changeset_for("string", "string_value", "*", template)
    refute changeset.valid?
  end

  test "valid type url", %{template: template} do
    changeset = get_changeset_for("url", %{}, "?", template)
    assert changeset.valid?
  end

  test "invalid type url", %{template: template} do
    changeset = get_changeset_for("url", "string_value", "?", template)
    refute changeset.valid?
  end

  test "valid type enriched_text", %{template: template} do
    changeset = get_changeset_for("enriched_text", %{}, "?", template)
    assert changeset.valid?
  end

  test "invalid string type enriched_text", %{template: template} do
    changeset = get_changeset_for("enriched_text", "my_string", "1", template)
    refute changeset.valid?
  end

  test "invalid array type enriched_text", %{template: template} do
    changeset = get_changeset_for("enriched_text", ["my_string"], "1", template)
    refute changeset.valid?
  end

  test "invalid required type string cardinality 1", %{template: template} do
    changeset = get_changeset_for("string", "", "1", template)
    refute changeset.valid?
    changeset = get_changeset_for("string", nil, "1", template)
    refute changeset.valid?
  end

  test "valid not required type string cardinality ?", %{template: template} do
    changeset = get_changeset_for("string", "", "?", template)
    assert changeset.valid?
    changeset = get_changeset_for("string", nil, "?", template)
    assert changeset.valid?
  end

  test "invalid required type string cardinality +", %{template: template} do
    changeset = get_changeset_for("string", [], "+", template)
    refute changeset.valid?
    changeset = get_changeset_for("string", nil, "+", template)
    refute changeset.valid?
    changeset = get_changeset_for("string", [nil], "+", template)
    refute changeset.valid?
    changeset = get_changeset_for("string", [""], "+", template)
    refute changeset.valid?
    changeset = get_changeset_for("string", [[]], "+", template)
    refute changeset.valid?
  end

  test "valid not required type string cardinality *", %{template: template} do
    changeset = get_changeset_for("string", [], "*", template)
    assert changeset.valid?
    changeset = get_changeset_for("string", nil, "*", template)
    assert changeset.valid?
  end

  test "invalid content for string cardinality *", %{template: template} do
    changeset = get_changeset_for("string", ["valid", 123], "*", template)
    refute changeset.valid?
  end

  # @string -> :string
  test "string field is valid with string value", %{template: template} do
    changeset = get_changeset_for("string", "string", "1", template)
    assert changeset.valid?
  end

  test "string field is invalid with integer value", %{template: template} do
    changeset = get_changeset_for("string", 123, "1", template)
    refute changeset.valid?
  end

  test "content with hidden required field returns valid changeset", %{template: template} do
    template =
      template
      |> Map.put(
        :content,
        [
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
          }
        ]
      )

    {:ok, _} = TemplateCache.put(template)

    {:ok, schema} = TemplateCache.get(template.id, :content)
    changeset = Validation.build_changeset(%{"radio_list" => "No"}, schema)
    assert changeset.valid?
  end

  test "content with depend required not set field returns invalid changeset", %{
    template: template
  } do
    template =
      template
      |> Map.put(:content, [
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
        }
      ])

    {:ok, _} = TemplateCache.put(template)

    {:ok, schema} = TemplateCache.get(template.id, :content)
    changeset = Validation.build_changeset(%{"radio_list" => "Yes"}, schema)
    refute changeset.valid?
  end

  test "content with depend required set field returns valid changeset", %{template: template} do
    template =
      template
      |> Map.put(:content, [
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
        }
      ])

    {:ok, _} = TemplateCache.put(template)

    content = %{"radio_list" => "Yes", "dependant_text" => "value"}
    {:ok, schema} = TemplateCache.get(template.id, :content)
    changeset = Validation.build_changeset(content, schema)
    assert changeset.valid?
  end

  defp random_template do
    id = random_id()

    %{
      id: id,
      name: "Template #{id}",
      label: "Label #{id}",
      scope: "Scope #{id}",
      content: [%{"name" => "field", "type" => "string"}],
      updated_at: DateTime.utc_now()
    }
  end

  defp random_id, do: :rand.uniform(100_000_000)
end
