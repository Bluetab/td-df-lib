defmodule TdDfLib.ValidationTest do
  use ExUnit.Case

  import TdDfLib.Factory

  alias TdCache.TemplateCache
  alias TdDfLib.Validation

  @unsafe "javascript:alert(document)"

  describe "build_changeset/2 & build_changeset/3" do
    setup context do
      %{id: template_id} =
        template =
        case context[:template_content] do
          [_ | _] = content ->
            build(:template, content: content)

          nil ->
            build(:template)
        end

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
          %{
            "image_name" => %{
              "value" => <<"data:image/jpeg;base64,/888j/4QAYRXhXXXX">>,
              "origin" => "user"
            }
          },
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
          %{
            "image_name" => %{
              "value" => <<"data:application/pdf;base64,JVBERi0xLjUNJeLj">>,
              "origin" => "user"
            }
          },
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
          %{"hierarchy_field" => %{"value" => "234_52", "origin" => "user"}},
          schema
        )

      assert changeset.valid?

      changeset =
        Validation.build_changeset(
          %{"hierarchy_field" => %{"value" => "234_50", "origin" => "user"}},
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

    test "fields with error return not valid changeset", %{template: template} do
      template =
        template
        |> Map.put(
          :content,
          [
            %{
              "name" => "string",
              "type" => "string",
              "cardinality" => "?",
              "values" => %{"fixed" => ["one", "two", "three"]}
            }
          ]
        )

      {:ok, _} = TemplateCache.put(template)
      {:ok, schema} = TemplateCache.get(template.id, :content)

      error_mgs = "error in content"

      changeset =
        Validation.build_changeset(
          %{
            "string" => %{"value" => {:error, error_mgs}, "origin" => "user"}
          },
          schema
        )

      refute changeset.valid?

      assert %{
        errors: [string: error_mgs]
      }
    end

    test "fields multiple with error return not valid changeset", %{template: template} do
      template =
        template
        |> Map.put(
          :content,
          [
            %{
              "name" => "list",
              "type" => "string",
              "cardinality" => "*",
              "values" => %{"fixed" => ["one", "two", "three"]}
            }
          ]
        )

      {:ok, _} = TemplateCache.put(template)
      {:ok, schema} = TemplateCache.get(template.id, :content)

      error_mgs = "error in content"

      changeset =
        Validation.build_changeset(
          %{
            "list" => %{"value" => [{:error, error_mgs}, "two"], "origin" => "user"}
          },
          schema
        )

      refute changeset.valid?

      assert %{
        errors: [string: error_mgs]
      }
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
              "value" => {
                :error,
                [
                  %{"key" => "50_41", "name" => "foo"},
                  %{"key" => "50_51", "name" => "foo"}
                ]
              },
              "origin" => "user"
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
            "hierarchy_name" => %{
              "value" => [
                {
                  :error,
                  [
                    %{"key" => "50_41", "name" => "foo"},
                    %{"key" => "50_51", "name" => "foo"}
                  ]
                },
                {
                  :error,
                  [
                    %{"key" => "50_42", "name" => "bar"},
                    %{"key" => "50_52", "name" => "bar"}
                  ]
                }
              ],
              "origin" => "user"
            }
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

      changeset =
        Validation.build_changeset(
          %{"radio_list" => %{"value" => "No", "origin" => "user"}},
          schema
        )

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

      changeset =
        Validation.build_changeset(
          %{"radio_list" => %{"value" => "Yes", "origin" => "user"}},
          schema
        )

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

      changeset =
        Validation.build_changeset(
          %{"radio_list" => %{"value" => "Yes", "origin" => "user"}},
          schema
        )

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

      content = %{
        "radio_list" => %{"value" => "Yes", "origin" => "user"},
        "dependant_text" => %{"value" => "value", "origin" => "user"}
      }

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

      content = %{
        "dropdown_fixed_list" => %{"value" => "Yes", "origin" => "user"},
        "dropdown_fixed_tuple" => %{"value" => "No", "origin" => "user"}
      }

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

      content = %{"dropdown_fixed_list" => %{"value" => "Other", "origin" => "user"}}
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

      content = %{"dropdown_fixed_tuple" => %{"value" => "Other", "origin" => "user"}}
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

      content = %{
        "string" => %{"value" => "xyx", "origin" => "user"},
        "list" => %{"value" => "three", "origin" => "user"}
      }

      changeset = Validation.build_changeset(content, schema)

      assert %{
               errors: [dependent_multiple: {"can't be blank", [validation: :required]}],
               valid?: false
             } = changeset

      content = %{
        "string" => %{"value" => "xyx", "origin" => "user"},
        "list" => %{"value" => "one", "origin" => "user"}
      }

      changeset = Validation.build_changeset(content, schema)

      assert %{
               errors: [dependent_multiple: {"can't be blank", [validation: :required]}],
               valid?: false
             } = changeset

      content = %{
        "string" => %{"value" => "xyx", "origin" => "user"},
        "list" => %{"value" => "one", "origin" => "user"},
        "dependent_multiple" => %{"value" => ["foo"], "origin" => "user"}
      }

      changeset = Validation.build_changeset(content, schema)
      assert %{valid?: true} = changeset

      content = %{
        "string" => %{"value" => "xyx", "origin" => "user"},
        "list" => %{"value" => "two", "origin" => "user"}
      }

      changeset = Validation.build_changeset(content, schema)

      assert %{
               errors: [dependent_single: {"can't be blank", [validation: :required]}],
               valid?: false
             } = changeset

      content = %{
        "string" => %{"value" => "xyx", "origin" => "user"},
        "list" => %{"value" => "two", "origin" => "user"},
        "dependent_single" => %{"value" => "bar", "origin" => "user"}
      }

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

      content = %{
        "string" => %{"value" => "foo", "origin" => "user"},
        "list" => %{"value" => "one", "origin" => "user"},
        "domain_dependent" => %{"value" => ["xyz"], "origin" => "user"}
      }

      changeset = Validation.build_changeset(content, schema, domain_ids: [1, 3])

      assert %{
               errors: [
                 domain_dependent:
                   {"has an invalid entry",
                    [validation: :subset, enum: ["foo", "bar", "baz", "wtf"]]}
               ],
               valid?: false
             } = changeset

      content = %{
        "string" => %{"value" => "foo", "origin" => "user"},
        "list" => %{"value" => "one", "origin" => "user"},
        "domain_dependent" => %{"value" => ["xyz"], "origin" => "user"}
      }

      assert %{valid?: true} = Validation.build_changeset(content, schema, domain_id: 2)

      assert %{
               changes: changes,
               valid?: true
             } = Validation.build_changeset(content, schema)

      refute Map.has_key?(changes, :domain_dependent)
    end

    @tag template_content: [
           %{
             "name" => "group",
             "fields" => [
               %{
                 "cardinality" => "?",
                 "default" => %{"value" => "", "origin" => "user"},
                 "label" => "User list",
                 "name" => "data_owner",
                 "type" => "user",
                 "values" => %{"processed_users" => [], "role_users" => "Data Owner"},
                 "widget" => "dropdown"
               }
             ]
           }
         ]
    test "validates user role values", %{template: template} do
      domain = CacheHelpers.put_domain()
      user = CacheHelpers.insert_user()
      CacheHelpers.insert_acl(domain.id, "Data Owner", [user.id])
      content = %{"data_owner" => %{"value" => "foo", "origin" => "user"}}
      schema = Enum.flat_map(template.content, & &1["fields"])

      %Ecto.Changeset{valid?: false, errors: errors} =
        Validation.build_changeset(content, schema, domain_ids: [domain.id])

      assert errors[:data_owner] ==
               {"is invalid", [validation: :inclusion, enum: [user.full_name]]}

      content = %{"data_owner" => %{"value" => user.full_name, "origin" => "user"}}

      %Ecto.Changeset{valid?: true, changes: changes} =
        Validation.build_changeset(content, schema, domain_ids: [domain.id])

      assert changes == %{data_owner: user.full_name}
    end

    @tag template_content: [
           %{
             "name" => "group",
             "fields" => [
               %{
                 "cardinality" => "?",
                 "default" => %{"value" => "", "origin" => "user"},
                 "label" => "List of users/groups",
                 "name" => "data_owner",
                 "type" => "user_group",
                 "values" => %{"processed_users" => [], "role_groups" => "Data Owner"},
                 "widget" => "dropdown"
               }
             ]
           }
         ]
    test "validates user group content", %{template: template} do
      domain = CacheHelpers.put_domain()
      user = CacheHelpers.insert_user()
      group = CacheHelpers.insert_group()
      CacheHelpers.insert_acl(domain.id, "Data Owner", [user.id])
      CacheHelpers.insert_group_acl(domain.id, "Data Owner", [group.id])

      schema = Enum.flat_map(template.content, & &1["fields"])
      content = %{"data_owner" => %{"value" => "user:foo", "origin" => "user"}}

      # Invalid user
      %Ecto.Changeset{valid?: false, errors: errors} =
        Validation.build_changeset(content, schema, domain_ids: [domain.id])

      assert {"is invalid", [validation: :inclusion, enum: enum]} = errors[:data_owner]

      assert "user:#{user.full_name}" in enum
      assert "group:#{group.name}" in enum

      # Invalid group
      content = %{"data_owner" => %{"value" => "group:foo", "origin" => "user"}}

      %Ecto.Changeset{valid?: false, errors: errors} =
        Validation.build_changeset(content, schema, domain_ids: [domain.id])

      assert {"is invalid", [validation: :inclusion, enum: enum]} = errors[:data_owner]

      assert "user:#{user.full_name}" in enum
      assert "group:#{group.name}" in enum

      # Valid user
      content = %{"data_owner" => %{"value" => "user:#{user.full_name}", "origin" => "user"}}

      %Ecto.Changeset{valid?: true, changes: changes} =
        Validation.build_changeset(content, schema, domain_ids: [domain.id])

      assert changes == %{data_owner: "user:#{user.full_name}"}

      # Valid group
      content = %{"data_owner" => %{"value" => "group:#{group.name}", "origin" => "user"}}

      %Ecto.Changeset{valid?: true, changes: changes} =
        Validation.build_changeset(content, schema, domain_ids: [domain.id])

      assert changes == %{data_owner: "group:#{group.name}"}
    end

    @tag template_content: [
           %{
             "name" => "group",
             "fields" => [
               %{
                 "ai_suggestion" => false,
                 "cardinality" => "+",
                 "default" => %{
                   "origin" => "default",
                   "value" => ""
                 },
                 "label" => "Hierarchy multiple",
                 "name" => "multiple_hierarchy",
                 "subscribable" => false,
                 "type" => "hierarchy",
                 "values" => %{
                   "hierarchy" => %{
                     "id" => 1,
                     "min_depth" => "0"
                   }
                 },
                 "widget" => "dropdown"
               },
               %{
                 "cardinality" => "1",
                 "default" => "",
                 "label" => "Enriched text",
                 "name" => "enriched_text",
                 "type" => "enriched_text",
                 "values" => nil,
                 "widget" => "text"
               },
               %{
                 "ai_suggestion" => false,
                 "name" => "multiple_string",
                 "type" => "string",
                 "cardinality" => "+"
               }
             ]
           }
         ]
    test "validates required fields with multiple cardinality", %{template: template} do
      schema = Enum.flat_map(template.content, & &1["fields"])

      content = %{
        "multiple_hierarchy" => %{"origin" => "file", "value" => []},
        "enriched_text" => %{"origin" => "file", "value" => %{}},
        "multiple_string" => %{"origin" => "file", "value" => [nil]}
      }

      %Ecto.Changeset{valid?: false, errors: errors} =
        Validation.build_changeset(content, schema, [])

      assert {_message, min_length_validation} = errors[:multiple_hierarchy]

      assert Keyword.equal?(min_length_validation,
               validation: :length,
               kind: :min,
               type: :list,
               count: 1
             )

      assert {_message, empty_object_validation} = errors[:enriched_text]
      assert empty_object_validation[:validation] == :required

      assert {_message, multiple_string_validation} = errors[:multiple_string]
      assert multiple_string_validation[:validation] == :required
    end
  end

  describe "validator/2" do
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

      assert [{:content, {"list: is invalid - string: can't be blank", _errors}}] =
               validator.(:content, %{"list" => %{"value" => "four", "origin" => "user"}})

      assert [{:content, "invalid content"}] =
               validator.(:content, %{
                 "list" => %{"value" => "one", "origin" => "user"},
                 "string" => %{"value" => @unsafe, "origin" => "user"}
               })
    end

    test "returns a validator that join all errors", %{template: %{name: template_name}} do
      validator = Validation.validator(template_name)
      assert is_function(validator, 2)

      assert [{:content, {"string: can't be blank - list: is invalid", _}}] =
               validator.(:content, %{"list" => %{"value" => ["four"], "origin" => "user"}})
    end

    test "returns a validator that validates translation errors", %{
      template: %{name: template_name}
    } do
      validator = Validation.validator(template_name)
      assert is_function(validator, 2)

      assert [{:content, {"list: translation not found", [list: :no_translation_found]}}] =
               validator.(:content, %{
                 "string" => %{"value" => "one", "origin" => "user"},
                 "list" => %{"value" => {:error, :no_translation_found}, "origin" => "user"}
               })
    end

    test "returns valid changeset for permitted origins" do
      allowed_origins = Validation.allowed_origins()

      content =
        Enum.reduce(allowed_origins, %{}, fn origin, acc ->
          Map.put(acc, origin, %{"value" => origin, "origin" => origin})
        end)

      schema =
        Enum.map(allowed_origins, fn origin ->
          %{
            "cardinality" => "1",
            "group" => "group_name48",
            "label" => "#{origin} label",
            "name" => origin,
            "type" => "string",
            "values" => nil
          }
        end)

      changeset = Validation.build_changeset(content, schema)

      assert %{valid?: true, errors: []} = changeset
    end

    test "returns invalid changeset for not permitted origins" do
      not_allowed_domains = ["stop", "inventing"]

      content =
        Enum.reduce(not_allowed_domains, %{}, fn origin, acc ->
          Map.put(acc, origin, %{"value" => origin, "origin" => origin})
        end)

      schema =
        Enum.map(not_allowed_domains, fn origin ->
          %{
            "cardinality" => "1",
            "group" => "group_name48",
            "label" => "#{origin} label",
            "name" => origin,
            "type" => "string",
            "values" => nil
          }
        end)

      changeset = Validation.build_changeset(content, schema)

      assert %{valid?: false, errors: errors} = changeset

      assert {"invalid origin", [origin: "stop"]} = Access.get(errors, :stop)
      assert {"invalid origin", [origin: "inventing"]} = Access.get(errors, :inventing)
    end
  end

  describe "validate_safe/2" do
    test "returns an empty list if content is safe" do
      assert Validation.validate_safe(:foo, %{"href" => "http:/foo.bar"}) == []
      assert Validation.validate_safe(:foo, [%{id: 1}, %{foo: "bar"}]) == []
      assert Validation.validate_safe(:foo, "a safe sting") == []
      assert Validation.validate_safe(:foo, nil) == []
      assert Validation.validate_safe(:foo, %{"bar" => {:error, "Error test"}}) == []
    end

    test "returns error keyword list if content in unsafe" do
      expected = [foo: "invalid content"]

      assert Validation.validate_safe(:foo, @unsafe) == expected
      assert Validation.validate_safe(:foo, [@unsafe, "hello"]) == expected
      assert Validation.validate_safe(:foo, %{"doc" => %{"href" => @unsafe}}) == expected
      assert Validation.validate_safe(:foo, %{"bar" => {:error, @unsafe}}) == expected
    end
  end

  describe "allowed_origins/0" do
    test "returns allowed origins list" do
      allowed_origins = ["user", "ai", "default", "autogenerated", "file"]

      assert allowed_origins == Validation.allowed_origins()
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

    content = %{"field" => %{"value" => field_value, "origin" => "user"}}
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
