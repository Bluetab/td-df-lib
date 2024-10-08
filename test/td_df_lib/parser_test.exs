defmodule TdDfLib.ParserTest do
  use ExUnit.Case

  import TdDfLib.Factory
  alias TdDfLib.Parser

  @field_name "field_name"
  @atom_field_name String.to_atom(@field_name)

  describe "format_content/1" do
    test "format fixed values with single cardinality and lang" do
      content = %{"i18n" => %{"value" => "uno", "origin" => "user"}}

      schema = [
        %{
          "cardinality" => "?",
          "group" => "group",
          "label" => "label i18n",
          "name" => "i18n",
          "type" => "string",
          "values" => %{"fixed" => ["one", "two", "three"]},
          "widget" => "dropdown"
        }
      ]

      CacheHelpers.put_i18n_message("es", %{
        message_id: "fields.label i18n.one",
        definition: "uno"
      })

      assert %{"i18n" => %{"value" => "one", "origin" => "user"}} =
               Parser.format_content(%{
                 content: content,
                 content_schema: schema,
                 domain_ids: [],
                 lang: "es"
               })
    end

    test "format fixed values with single cardinality and lang but not 18n key" do
      content = %{"i18n" => %{"value" => "uno", "origin" => "user"}}

      schema = [
        %{
          "cardinality" => "?",
          "group" => "group",
          "label" => "label i18n",
          "name" => "i18n",
          "type" => "string",
          "values" => %{"fixed" => ["one", "two", "three"]},
          "widget" => "dropdown"
        }
      ]

      assert %{"i18n" => %{"value" => "uno", "origin" => "user"}} =
               Parser.format_content(%{
                 content: content,
                 content_schema: schema,
                 domain_ids: [],
                 lang: "es"
               })
    end

    test "format fixed values with multiple cardinality and lang" do
      content = %{"i18n" => %{"value" => "uno|dos", "origin" => "user"}}

      schema = [
        %{
          "cardinality" => "+",
          "group" => "group",
          "label" => "label i18n",
          "name" => "i18n",
          "type" => "string",
          "values" => %{"fixed" => ["one", "two", "three"]},
          "widget" => "checkbox"
        }
      ]

      CacheHelpers.put_i18n_message("es", %{
        message_id: "fields.label i18n.one",
        definition: "uno"
      })

      CacheHelpers.put_i18n_message("es", %{
        message_id: "fields.label i18n.two",
        definition: "dos"
      })

      assert %{"i18n" => %{"value" => ["one", "two"], "origin" => "user"}} =
               Parser.format_content(%{
                 content: content,
                 content_schema: schema,
                 domain_ids: [],
                 lang: "es"
               })
    end

    test "format fixed values with multiple cardinality and lang but not i18n key" do
      content = %{"i18n" => %{"value" => "uno|dos", "origin" => "user"}}

      schema = [
        %{
          "cardinality" => "+",
          "group" => "group",
          "label" => "label i18n",
          "name" => "i18n",
          "type" => "string",
          "values" => %{"fixed" => ["one", "two", "three"]},
          "widget" => "checkbox"
        }
      ]

      assert %{"i18n" => %{"value" => ["uno", "dos"], "origin" => "user"}} =
               Parser.format_content(%{
                 content: content,
                 content_schema: schema,
                 domain_ids: [],
                 lang: "es"
               })
    end

    test "format fixed values with multiple cardinality and some missing 18n key" do
      content = %{"i18n" => %{"value" => "uno|tres", "origin" => "user"}}

      schema = [
        %{
          "cardinality" => "+",
          "group" => "group",
          "label" => "label i18n",
          "name" => "i18n",
          "type" => "string",
          "values" => %{"fixed" => ["one", "two", "three"]},
          "widget" => "checkbox"
        }
      ]

      CacheHelpers.put_i18n_message("es", %{
        message_id: "fields.label i18n.one",
        definition: "uno"
      })

      CacheHelpers.put_i18n_message("es", %{
        message_id: "fields.label i18n.two",
        definition: "dos"
      })

      assert %{"i18n" => %{"value" => ["one", "tres"], "origin" => "user"}} =
               Parser.format_content(%{
                 content: content,
                 content_schema: schema,
                 domain_ids: [],
                 lang: "es"
               })
    end

    test "format value as map with value and origin" do
      content = %{
        "term1" => %{"value" => "value1", "origin" => "user"},
        "term2" => %{"value" => "value2", "origin" => "ai"},
        "term3" => %{"value" => "value3", "origin" => "default"},
        "term4" => %{"value" => "value4", "origin" => "autogenerated"}
      }

      schema =
        Enum.map(content, fn {key, _} ->
          %{
            "cardinality" => "1",
            "group" => "Basic",
            "label" => "#{key} label",
            "name" => key,
            "type" => "string",
            "values" => nil,
            "widget" => "string"
          }
        end)

      assert content ==
               Parser.format_content(%{
                 content: content,
                 content_schema: schema,
                 domain_ids: []
               })
    end

    test "format content with default values" do
      content = %{
        "term1" => %{"value" => "value1", "origin" => "user"},
        "term2" => %{"value" => "one|two", "origin" => "ai"}
      }

      schema = [
        %{
          "cardinality" => "1",
          "group" => "Basic",
          "label" => "term1 label",
          "name" => "term1",
          "type" => "string",
          "values" => nil,
          "widget" => "string"
        },
        %{
          "cardinality" => "+",
          "group" => "group",
          "label" => "term2 label",
          "name" => "term2",
          "type" => "string",
          "values" => %{"fixed" => ["one", "two", "three"]},
          "widget" => "checkbox"
        },
        %{
          "cardinality" => "1",
          "default" => %{"value" => "default value", "origin" => "default"},
          "group" => "Basic",
          "label" => "default1 label",
          "name" => "default1",
          "type" => "string",
          "values" => nil,
          "widget" => "string"
        },
        %{
          "cardinality" => "1",
          "default" => %{"value" => ["one", "two"], "origin" => "default"},
          "group" => "Basic",
          "label" => "default2 label",
          "name" => "default2",
          "type" => "string",
          "values" => %{"fixed" => ["one", "two", "three"]},
          "widget" => "checkbox"
        }
      ]

      assert %{
               "term1" => %{"value" => "value1", "origin" => "user"},
               "term2" => %{"origin" => "ai", "value" => ["one", "two"]},
               "default1" => %{"value" => "default value", "origin" => "default"},
               "default2" => %{"origin" => "default", "value" => ["one", "two"]}
             } ==
               Parser.format_content(%{
                 content: content,
                 content_schema: schema,
                 domain_ids: []
               })
    end

    test "format user and group values with multiple cardinality" do
      schema = [
        %{
          "cardinality" => "*",
          "name" => "data_owner",
          "type" => "user_group",
          "label" => "List of users/groups",
          "values" => %{"processed_users" => [], "role_groups" => "Data Owner"},
          "widget" => "dropdown"
        },
        %{
          "cardinality" => "+",
          "name" => "data_officer",
          "type" => "user",
          "label" => "List of users",
          "values" => %{"processed_users" => [], "role_users" => "Data Officer"},
          "widget" => "dropdown"
        }
      ]

      content = %{
        "data_owner" => %{"origin" => "file", "value" => "user:user|group:group"},
        "data_officer" => %{"origin" => "file", "value" => "user|user1"}
      }

      assert %{
               "data_owner" => %{"origin" => "file", "value" => ["user:user", "group:group"]},
               "data_officer" => %{"origin" => "file", "value" => ["user", "user1"]}
             } ==
               Parser.format_content(%{
                 content: content,
                 content_schema: schema,
                 domain_ids: []
               })
    end

    test "foo" do
      schema = [
        %{
          "cardinality" => "?",
          "default" => %{"value" => "", "origin" => "default"},
          "description" => "Input your integer",
          "label" => "Number",
          "name" => "input_integer",
          "type" => "integer",
          "widget" => "number",
          "values" => nil
        },
        %{
          "cardinality" => "?",
          "default" => %{"value" => "", "origin" => "default"},
          "description" => "Input your float",
          "label" => "Number",
          "name" => "input_float",
          "type" => "float",
          "widget" => "number",
          "values" => nil
        }
      ]

      content = %{
        "input_float" => %{"origin" => "file", "value" => "foo"},
        "input_integer" => %{"origin" => "file", "value" => "bar"}
      }

      fields =
        Parser.format_content(%{
          content: content,
          content_schema: schema,
          domain_ids: []
        })

      assert fields["input_float"]["value"] == {:error, :invalid_format}
      assert fields["input_integer"]["value"] == {:error, :invalid_format}
    end
  end

  describe "get_from_content/2" do
    test "return value from content for a given key" do
      content = %{
        "term1" => %{"value" => "value1", "origin" => "user"},
        "term2" => %{"value" => "value2", "origin" => "ai"},
        "term3" => %{"value" => "value3", "origin" => "default"}
      }

      assert %{
               "term1" => "value1",
               "term2" => "value2",
               "term3" => "value3"
             } = Parser.get_from_content(content, "value")

      assert %{
               "term1" => "user",
               "term2" => "ai",
               "term3" => "default"
             } = Parser.get_from_content(content, "origin")
    end
  end

  describe "append_parsed_fields/3" do
    test "formats type url" do
      url_value = "url_value"
      fields = [%{"type" => "url", "name" => @field_name}]
      content = %{@atom_field_name => %{"value" => %{url_value: url_value}, "origin" => "user"}}

      assert Parser.append_parsed_fields([], fields, content) == [url_value]
    end

    test "formats type domain using external id by default and if specified" do
      %{id: domain_id_1} = CacheHelpers.put_domain(external_id: "domain_1_external_id")
      %{id: domain_id_2} = CacheHelpers.put_domain(external_id: "domain_2_external_id")

      fields = [%{"type" => "domain", "name" => @field_name}]

      content = %{
        @atom_field_name => %{"value" => [domain_id_1, domain_id_2], "origin" => "user"}
      }

      assert Parser.append_parsed_fields([], fields, content) == [
               "domain_1_external_id|domain_2_external_id"
             ]

      assert Parser.append_parsed_fields([], fields, content,
               domain_type: :with_domain_external_id
             ) == [
               "domain_1_external_id|domain_2_external_id"
             ]
    end

    test "formats type domain using name when specified" do
      %{id: domain_id_1} =
        CacheHelpers.put_domain(external_id: "domain_1_external_id", name: "domain_1_name")

      %{id: domain_id_2} =
        CacheHelpers.put_domain(external_id: "domain_2_external_id", name: "domain_2_name")

      fields = [%{"type" => "domain", "name" => @field_name}]

      content = %{
        @atom_field_name => %{"value" => [domain_id_1, domain_id_2], "origin" => "user"}
      }

      assert Parser.append_parsed_fields([], fields, content, domain_type: :with_domain_name) == [
               "domain_1_name|domain_2_name"
             ]
    end

    test "formats type hierarchy" do
      %{nodes: [%{name: node1_name}, %{name: node2_name}]} =
        CacheHelpers.insert_hierarchy(
          id: 1927,
          nodes: [
            build(:node, %{node_id: 50, parent_id: nil, hierarchy_id: 1927}),
            build(:node, %{node_id: 51, parent_id: nil, hierarchy_id: 1927})
          ]
        )

      fields = [
        %{
          "type" => "hierarchy",
          "name" => @field_name,
          "values" => %{"hierarchy" => %{"id" => 1927}}
        }
      ]

      content = %{@atom_field_name => %{"value" => ["1927_50", "1927_51"], "origin" => "user"}}

      assert Parser.append_parsed_fields([], fields, content) == ["/#{node1_name}|/#{node2_name}"]
    end

    test "formats type system" do
      fields = [%{"type" => "system", "name" => @field_name}]
      content = %{@atom_field_name => %{"value" => %{name: "system"}, "origin" => "user"}}

      assert Parser.append_parsed_fields([], fields, content) == ["system"]
    end

    test "formats fixed tuple" do
      values = [
        %{"value" => "v1", "text" => "t1"},
        %{"value" => "v2", "text" => "t2"}
      ]

      fields = [
        %{
          "label" => "bar",
          "type" => "string",
          "name" => @field_name,
          "values" => %{"fixed_tuple" => values}
        }
      ]

      content = %{@atom_field_name => %{"value" => ["v1", "v2"], "origin" => "user"}}

      assert Parser.append_parsed_fields([], fields, content) == ["t1|t2"]
    end

    test "formats fixed tuple with i18n" do
      values = [
        %{"value" => "v1", "text" => "t1"},
        %{"value" => "v2", "text" => "t2"}
      ]

      fields = [
        %{
          "label" => "bar",
          "type" => "string",
          "name" => @field_name,
          "values" => %{"fixed_tuple" => values}
        }
      ]

      content = %{@atom_field_name => %{"value" => ["v1", "v2"], "origin" => "user"}}

      lang = "en"

      CacheHelpers.put_i18n_message(lang, %{message_id: "fields.bar.t1", definition: "english_t1"})

      assert Parser.append_parsed_fields([], fields, content, lang: lang) == ["english_t1|t2"]
    end

    test "formats fixed with i18n" do
      fields = [
        %{
          "label" => "bar",
          "type" => "string",
          "name" => @field_name,
          "values" => %{"fixed" => ["v1", "v2", "v3"]}
        }
      ]

      content = %{@atom_field_name => %{"value" => ["v1", "v2"], "origin" => "user"}}

      lang = "en"

      CacheHelpers.put_i18n_message(lang, %{message_id: "fields.bar.v1", definition: "english_v1"})

      CacheHelpers.put_i18n_message(lang, %{message_id: "fields.bar.v3", definition: "english_v3"})

      assert Parser.append_parsed_fields([], fields, content, lang: lang) == ["english_v1|v2"]
    end

    test "formats switch on with i18n" do
      fields = [
        %{
          "label" => "category",
          "mandatory" => %{"on" => "Dependent"},
          "name" => "Category",
          "type" => "string",
          "values" => %{"fixed" => ["a", "b", "c"]}
        },
        %{
          "label" => "dependent",
          "type" => "string",
          "mandatory" => %{"on" => "", "to_be" => []},
          "name" => "Dependent",
          "values" => %{
            "switch" => %{
              "on" => "Category",
              "values" => %{"A" => ["one"], "B" => ["two"]}
            }
          }
        }
      ]

      content = %{
        "Category" => %{"value" => "A", "origin" => "user"},
        "Dependent" => %{"value" => "one", "origin" => "user"}
      }

      lang = "es"

      CacheHelpers.put_i18n_message(lang, %{message_id: "fields.category.a", definition: "A"})
      CacheHelpers.put_i18n_message(lang, %{message_id: "fields.category.b", definition: "B"})
      CacheHelpers.put_i18n_message(lang, %{message_id: "fields.category.c", definition: "C"})

      CacheHelpers.put_i18n_message(lang, %{message_id: "fields.dependent.one", definition: "Uno"})

      CacheHelpers.put_i18n_message(lang, %{message_id: "fields.dependent.two", definition: "Dos"})

      assert Parser.append_parsed_fields([], fields, content, lang: lang) == ["A", "Uno"]
    end

    test "type table is formated as empty string" do
      assert Parser.append_parsed_fields([], %{"type" => "table"}, nil) == [""]
    end

    test "field named tags is formatted" do
      fields = [%{"name" => "tags"}]
      content = %{tags: %{"value" => ["tag1", "tag2"], "origin" => "user"}}

      assert Parser.append_parsed_fields([], fields, content) == ["tag1|tag2"]
    end

    test "formats field to string" do
      fields = [%{"name" => @field_name}]
      content = %{@atom_field_name => %{"value" => "value", "origin" => "user"}}

      assert Parser.append_parsed_fields([], fields, content) == ["value"]
    end
  end
end
