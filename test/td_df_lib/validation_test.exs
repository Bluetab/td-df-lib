defmodule TdDfLib.ValidationTest do
  use ExUnit.Case

  import TdDfLib.Factory

  alias TdCache.TemplateCache
  alias TdDfLib.Validation

  @unsafe "javascript:alert(document)"

  describe "validations" do
    setup do
      %{id: template_id} = template = build(:template)
      hierarchy = create_hierarchy(234)

      on_exit(fn -> TemplateCache.delete(template_id) end)

      [template: template, hierarchy: hierarchy]
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

    test "depth validation on hierarchy node selection", %{
      template: template,
      hierarchy: %{id: hierarchy_id}
    } do
      template =
        template
        |> Map.put(
          :content,
          [
            %{
              "name" => "hierarchy_field",
              "type" => "hierarchy",
              "cardinality" => "1",
              "values" => %{"hierarchy" => %{"id" => hierarchy_id, "min_depth" => 2}}
            }
          ]
        )

      {:ok, _} = TemplateCache.put(template)
      {:ok, schema} = TemplateCache.get(template.id, :content)

      changeset =
        Validation.build_changeset(
          %{"hierarchy_field" => "234_52"},
          schema
        )

      assert changeset.valid?

      changeset =
        Validation.build_changeset(
          %{"hierarchy_field" => "234_50"},
          schema
        )

      refute changeset.valid?
    end

    test "depth validation", %{hierarchy: %{nodes: nodes} = hierarchy} do
      hierarchy = %{
        hierarchy
        | nodes:
            Enum.map(nodes, fn reg ->
              reg
              |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
              |> Enum.into(%{})
            end)
      }

      assert Validation.validate_hierarchy_depth(hierarchy, "234_52", 0)
      assert Validation.validate_hierarchy_depth(hierarchy, "234_52", 1)
      assert Validation.validate_hierarchy_depth(hierarchy, "234_52", 2)
      refute Validation.validate_hierarchy_depth(hierarchy, "234_52", 3)
      assert Validation.validate_hierarchy_depth(hierarchy, "234_53", 3)
      assert Validation.validate_hierarchy_depth(hierarchy, ["234_52", "234_53"], 1)
      refute Validation.validate_hierarchy_depth(hierarchy, ["234_52", "234_53"], 3)

      refute Validation.validate_hierarchy_depth(hierarchy, "234_52", "3")
      assert Validation.validate_hierarchy_depth(hierarchy, "234_53", "3")
      assert Validation.validate_hierarchy_depth(hierarchy, "234_53", "")
      refute Validation.validate_hierarchy_depth(hierarchy, "234_53", "abc")

      assert Validation.validate_hierarchy_depth(hierarchy, "", 3)
      assert Validation.validate_hierarchy_depth(hierarchy, [], 3)
      assert Validation.validate_hierarchy_depth(hierarchy, [""], 3)
      assert Validation.validate_hierarchy_depth(hierarchy, nil, 89)
    end

    test "invalid hierarchy with more than one node paths", %{template: template} do
      template =
        template
        |> Map.put(
          :content,
          [
            %{
              "name" => "hierarchy_name",
              "type" => "hierarchy",
              "cardinality" => "1",
              "values" => %{"hierarchy" => 1, "depth" => 0}
            }
          ]
        )

      {:ok, _} = TemplateCache.put(template)
      {:ok, schema} = TemplateCache.get(template.id, :content)

      changeset =
        Validation.build_changeset(
          %{
            "hierarchy_name" => %{
              :error => [
                %{"key" => "50_41", "name" => "foo"},
                %{"key" => "50_51", "name" => "foo"}
              ]
            }
          },
          schema
        )

      refute changeset.valid?
    end

    test "invalid hierarchy with more than one node paths and cardinality +", %{
      template: template
    } do
      template =
        template
        |> Map.put(
          :content,
          [
            %{
              "cardinality" => "1",
              "name" => "hierarchy_name",
              "type" => "hierarchy",
              "values" => %{"hierarchy" => 1, "depth" => 0}
            }
          ]
        )

      {:ok, _} = TemplateCache.put(template)
      {:ok, schema} = TemplateCache.get(template.id, :content)

      changeset =
        Validation.build_changeset(
          %{
            "hierarchy_name" => [
              %{
                :error => [
                  %{"key" => "50_41", "name" => "foo"},
                  %{"key" => "50_51", "name" => "foo"}
                ]
              },
              %{
                :error => [
                  %{"key" => "50_42", "name" => "bar"},
                  %{"key" => "50_52", "name" => "bar"}
                ]
              }
            ]
          },
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

    test "content with required dependant field is validated", %{template: template} do
      template =
        template
        |> Map.put(
          :content,
          [
            %{
              "name" => "radio_list",
              "type" => "string",
              "cardinality" => "*",
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
      changeset = Validation.build_changeset(%{"radio_list" => ["Yes"]}, schema)
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

    test "build_changeset/1 validates conditional mandatory fields", %{
      template: template
    } do
      %{content: [group = %{"fields" => fields} | _]} = template

      dependent_multiple = %{
        "name" => "dependent_multiple",
        "label" => "Dependent mandatory multiple",
        "type" => "string",
        "cardinality" => "*",
        "mandatory" => %{"on" => "list", "to_be" => ["one", "three"]},
        "values" => %{
          "fixed" => ["foo", "bar", "baz"]
        }
      }

      dependent_single = %{
        "name" => "dependent_single",
        "label" => "Dependent mandatory single",
        "type" => "string",
        "cardinality" => "?",
        "mandatory" => %{"on" => "list", "to_be" => ["two"]},
        "values" => nil
      }

      fields = fields ++ [dependent_multiple, dependent_single]
      group = Map.put(group, "fields", fields)
      template = Map.put(template, :content, [group])
      {:ok, _} = TemplateCache.put(template)
      {:ok, schema} = TemplateCache.get(template.id, :content)
      schema = Enum.flat_map(schema, &Map.get(&1, "fields"))
      content = %{"string" => "xyx", "list" => "three"}
      changeset = Validation.build_changeset(content, schema)

      assert %{
               errors: [dependent_multiple: {"can't be blank", [validation: :required]}],
               valid?: false
             } = changeset

      content = %{"string" => "xyx", "list" => "one"}
      changeset = Validation.build_changeset(content, schema)

      assert %{
               errors: [dependent_multiple: {"can't be blank", [validation: :required]}],
               valid?: false
             } = changeset

      content = %{"string" => "xyx", "list" => "one", "dependent_multiple" => ["foo"]}
      changeset = Validation.build_changeset(content, schema)
      assert %{valid?: true} = changeset
      content = %{"string" => "xyx", "list" => "two"}
      changeset = Validation.build_changeset(content, schema)

      assert %{
               errors: [dependent_single: {"can't be blank", [validation: :required]}],
               valid?: false
             } = changeset

      content = %{"string" => "xyx", "list" => "two", "dependent_single" => "bar"}
      changeset = Validation.build_changeset(content, schema)
      assert %{valid?: true} = changeset
    end

    test "build_changeset/1 validates field dependent on domain", %{
      template: template
    } do
      %{content: [group = %{"fields" => fields} | _]} = template

      domain = %{
        "name" => "domain_dependent",
        "label" => "Domain dependent field",
        "type" => "string",
        "cardinality" => "*",
        "values" => %{
          "domain" => %{1 => ["foo", "bar", "baz"], 2 => ["xyz"], 3 => ["wtf"]}
        }
      }

      fields = fields ++ [domain]
      group = Map.put(group, "fields", fields)
      template = Map.put(template, :content, [group])
      {:ok, _} = TemplateCache.put(template)
      {:ok, schema} = TemplateCache.get(template.id, :content)
      schema = Enum.flat_map(schema, &Map.get(&1, "fields"))
      content = %{"string" => "foo", "list" => "one", "domain_dependent" => ["xyz"]}
      changeset = Validation.build_changeset(content, schema, domain_ids: [1, 3])

      assert %{
               errors: [
                 domain_dependent:
                   {"has an invalid entry",
                    [validation: :subset, enum: ["foo", "bar", "baz", "wtf"]]}
               ],
               valid?: false
             } = changeset

      content = %{"string" => "foo", "list" => "one", "domain_dependent" => ["xyz"]}
      assert %{valid?: true} = Validation.build_changeset(content, schema, domain_id: 2)

      assert %{
               changes: changes,
               valid?: true
             } = Validation.build_changeset(content, schema)

      refute Map.has_key?(changes, :domain_dependent)
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

      assert [{:content, "invalid content"}] =
               validator.(:content, %{"list" => "one", "string" => @unsafe})
    end
  end

  describe "validate_safe/2" do
    test "returns an empty list if content is safe" do
      assert Validation.validate_safe(:foo, %{"href" => "http:/foo.bar"}) == []
      assert Validation.validate_safe(:foo, [%{id: 1}, %{foo: "bar"}]) == []
      assert Validation.validate_safe(:foo, "a safe sting") == []
      assert Validation.validate_safe(:foo, nil) == []
    end

    test "returns error keyword list if content in unsafe" do
      expected = [foo: "invalid content"]

      assert Validation.validate_safe(:foo, @unsafe) == expected
      assert Validation.validate_safe(:foo, [@unsafe, "hello"]) == expected
      assert Validation.validate_safe(:foo, %{"doc" => %{"href" => @unsafe}}) == expected
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

  defp create_hierarchy(hierarchy_id) do
    CacheHelpers.insert_hierarchy(
      id: hierarchy_id,
      nodes: [
        build(:node, %{
          node_id: 50,
          name: "father",
          parent_id: nil,
          hierarchy_id: hierarchy_id,
          path: "/father"
        }),
        build(:node, %{
          node_id: 51,
          name: "children_1",
          parent_id: 50,
          hierarchy_id: hierarchy_id,
          path: "/father/children_1"
        }),
        build(:node, %{
          node_id: 52,
          name: "children_2",
          parent_id: 51,
          hierarchy_id: hierarchy_id,
          path: "/father/children_1/children_2"
        }),
        build(:node, %{
          node_id: 53,
          name: "children_3",
          parent_id: 52,
          hierarchy_id: hierarchy_id,
          path: "/father/children_1/children_2/children_3"
        })
      ]
    )
  end
end
