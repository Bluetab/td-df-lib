defmodule TdDfLib.ValidationTest do
  use ExUnit.Case

  import TdDfLib.Factory

  alias TdCache.TemplateCache
  alias TdDfLib.Validation

  describe "validations" do
    setup do
      # template = random_template()
      %{id: template_id} = template = build(:template)
      # TemplateCache.put(template, publish: false)

      on_exit(fn -> TemplateCache.delete(template_id) end)

      [template: template]
    end

    test "empty content on empty template return valid changeset", %{template: template} do
      template = Map.put(template, :content, [])

      TemplateCache.put(template, publish: false)

      {:ok, schema} = TemplateCache.get(template.id, :content)
      changeset = Validation.build_changeset(%{}, schema)
      assert changeset.valid?
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

    test "copy field is valid with string value", %{template: template} do
      changeset = get_changeset_for("copy", "{value: string}", "1", template)
      assert changeset.valid?
    end

    test "copy field is invalid with integer value", %{template: template} do
      changeset = get_changeset_for("copy", 123, "1", template)
      refute changeset.valid?
    end

    test "copy field is invalid when mandatory and uniformed", %{template: template} do
      changeset = get_changeset_for("copy", nil, "1", template)
      refute changeset.valid?
    end

    test "copy field is invalid when mandatory and empty", %{template: template} do
      changeset = get_changeset_for("copy", "", "1", template)
      refute changeset.valid?
    end

    test "valid type system", %{template: template} do
      changeset = get_changeset_for("system", %{}, "?", template)
      assert changeset.valid?
    end

    test "valid type system in array", %{template: template} do
      changeset = get_changeset_for("system", [%{}], "*", template)
      assert changeset.valid?
    end

    test "invalid type system", %{template: template} do
      changeset = get_changeset_for("system", "string", "?", template)
      refute changeset.valid?
    end

    test "valid image type", %{template: template} do
      template =
        template
        |> Map.put(
          :content,
          [
            %{
              "cardinality" => "?",
              "default" => "",
              "label" => "image_label",
              "name" => "image_name",
              "type" => "image",
              "values" => nil,
              "widget" => "image"
            }
          ]
        )

      {:ok, _} = TemplateCache.put(template)
      {:ok, schema} = TemplateCache.get(template.id, :content)

      changeset =
        Validation.build_changeset(
          %{"image_name" => <<"data:image/jpeg;base64,/888j/4QAYRXhXXXX">>},
          schema
        )

      assert changeset.valid?
    end

    test "invalid image type", %{template: template} do
      template =
        template
        |> Map.put(
          :content,
          [
            %{
              "cardinality" => "?",
              "default" => "",
              "label" => "image_label",
              "name" => "image_name",
              "type" => "image",
              "values" => nil,
              "widget" => "image"
            }
          ]
        )

      {:ok, _} = TemplateCache.put(template)
      {:ok, schema} = TemplateCache.get(template.id, :content)

      changeset =
        Validation.build_changeset(
          %{"image_name" => <<"data:application/pdf;base64,JVBERi0xLjUNJeLj">>},
          schema
        )

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
              "values" => %{"fixed" => ["Yes", "No"]}
            },
            %{
              "name" => "dependant_text",
              "type" => "string",
              "cardinality" => "1",
              "depends" => %{"on" => "radio_list", "to_be" => ["Yes"]}
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
            "values" => %{"fixed" => ["Yes", "No"]}
          },
          %{
            "name" => "dependant_text",
            "type" => "string",
            "cardinality" => "1",
            "depends" => %{"on" => "radio_list", "to_be" => ["Yes"]}
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
            "values" => %{"fixed" => ["Yes", "No"]}
          },
          %{
            "name" => "dependant_text",
            "type" => "string",
            "cardinality" => "1",
            "depends" => %{"on" => "radio_list", "to_be" => ["Yes"]}
          }
        ])

      {:ok, _} = TemplateCache.put(template)

      content = %{"radio_list" => "Yes", "dependant_text" => "value"}
      {:ok, schema} = TemplateCache.get(template.id, :content)
      changeset = Validation.build_changeset(content, schema)
      assert changeset.valid?
    end

    test "content with correct values for fixed and fixed tuple values returns valid changeset",
         %{
           template: template
         } do
      template =
        template
        |> Map.put(:content, [
          %{
            "name" => "dropdown_fixed_list",
            "type" => "string",
            "cardinality" => "1",
            "values" => %{"fixed" => ["Yes", "No"]}
          },
          %{
            "name" => "dropdown_fixed_tuple",
            "type" => "string",
            "cardinality" => "1",
            "values" => %{
              "fixed_tuple" => [%{value: "Yes", text: "Yes!"}, %{value: "No", text: "No!"}]
            }
          }
        ])

      {:ok, _} = TemplateCache.put(template)

      content = %{"dropdown_fixed_list" => "Yes", "dropdown_fixed_tuple" => "No"}
      {:ok, schema} = TemplateCache.get(template.id, :content)
      changeset = Validation.build_changeset(content, schema)
      assert changeset.valid?
    end

    test "content with values not in fixed values returns invalid changeset", %{
      template: template
    } do
      template =
        template
        |> Map.put(:content, [
          %{
            "name" => "dropdown_fixed_list",
            "type" => "string",
            "cardinality" => "1",
            "values" => %{"fixed" => ["Yes", "No"]}
          }
        ])

      {:ok, _} = TemplateCache.put(template)

      content = %{"dropdown_fixed_list" => "Other"}
      {:ok, schema} = TemplateCache.get(template.id, :content)
      changeset = Validation.build_changeset(content, schema)
      refute changeset.valid?
    end

    test "content with values not in fixed tuple values returns invalid changeset", %{
      template: template
    } do
      template =
        template
        |> Map.put(:content, [
          %{
            "name" => "dropdown_fixed_tuple",
            "type" => "string",
            "cardinality" => "1",
            "values" => %{
              "fixed_tuple" => [%{value: "Yes", text: "Yes!"}, %{value: "No", text: "No!"}]
            }
          }
        ])

      {:ok, _} = TemplateCache.put(template)

      content = %{"dropdown_fixed_tuple" => "Other"}
      {:ok, schema} = TemplateCache.get(template.id, :content)
      changeset = Validation.build_changeset(content, schema)
      refute changeset.valid?
    end
  end

  describe "validator/1" do
    setup do
      %{id: template_id} = template = build(:template)
      TemplateCache.put(template, publish: false)

      on_exit(fn -> TemplateCache.delete(template_id) end)

      [template: template]
    end

    test "returns a validator that returns error if template is missing" do
      validator = Validation.validator("a_missing_template")

      assert is_function(validator, 2)

      assert validator.(:content, nil) == [
               content: {"invalid template", reason: :template_not_found}
             ]

      assert validator.(:content, %{}) == [
               content: {"invalid template", reason: :template_not_found}
             ]
    end

    test "returns a validator that validates dynamic content", %{template: %{name: template_name}} do
      validator = Validation.validator(template_name)
      assert is_function(validator, 2)

      assert [{:content, {"invalid content", _errors}}] =
               validator.(:content, %{"list" => "four"})
    end
  end

  defp get_changeset_for(field_type, field_value, cardinality, template) do
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
end
