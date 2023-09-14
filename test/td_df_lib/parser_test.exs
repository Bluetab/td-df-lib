defmodule TdDfLib.ParserTest do
  use ExUnit.Case

  import TdDfLib.Factory
  alias TdDfLib.Parser

  @field_name "field_name"
  @atom_field_name String.to_atom(@field_name)

  describe "format_content" do
    test "format_content format fixed values with single cardinality and translation" do
      content = %{"i18n" => "uno"}

      schema = [
        %{
          "cardinality" => "?",
          "group" => "group",
          "label" => "i18n",
          "name" => "i18n",
          "type" => "string",
          "values" => %{"fixed" => ["one", "two", "three"]},
          "widget" => "dropdown"
        }
      ]

      CacheHelpers.put_i18n_message("es", %{message_id: "fields.i18n.one", definition: "uno"})
      CacheHelpers.put_i18n_message("en", %{message_id: "fields.i18n.one", definition: "one"})

      assert %{"i18n" => "one"} =
               Parser.format_content(%{
                 content: content,
                 content_schema: schema,
                 domain_ids: [],
                 lang: "es"
               })
    end

    test "format_content format fixed values with single cardinality and translation error" do
      content = %{"i18n" => "uno"}

      schema = [
        %{
          "cardinality" => "?",
          "group" => "group",
          "label" => "i18n",
          "name" => "i18n",
          "type" => "string",
          "values" => %{"fixed" => ["one", "two", "three"]},
          "widget" => "dropdown"
        }
      ]

      assert %{"i18n" => {:error, :no_translation_found}} =
               Parser.format_content(%{
                 content: content,
                 content_schema: schema,
                 domain_ids: [],
                 lang: "es"
               })
    end

    test "format_content format fixed values with multiple cardinality and translation" do
      content = %{"i18n" => "uno|dos"}

      schema = [
        %{
          "cardinality" => "+",
          "group" => "group",
          "label" => "i18n",
          "name" => "i18n",
          "type" => "string",
          "values" => %{"fixed" => ["one", "two", "three"]},
          "widget" => "checkbox"
        }
      ]

      CacheHelpers.put_i18n_message("es", %{message_id: "fields.i18n.one", definition: "uno"})
      CacheHelpers.put_i18n_message("en", %{message_id: "fields.i18n.one", definition: "one"})
      CacheHelpers.put_i18n_message("es", %{message_id: "fields.i18n.two", definition: "dos"})
      CacheHelpers.put_i18n_message("en", %{message_id: "fields.i18n.two", definition: "two"})

      assert %{"i18n" => ["one", "two"]} =
               Parser.format_content(%{
                 content: content,
                 content_schema: schema,
                 domain_ids: [],
                 lang: "es"
               })
    end

    test "format_content format fixed values with multiple cardinality and translation error" do
      content = %{"i18n" => "uno|dos"}

      schema = [
        %{
          "cardinality" => "+",
          "group" => "group",
          "label" => "i18n",
          "name" => "i18n",
          "type" => "string",
          "values" => %{"fixed" => ["one", "two", "three"]},
          "widget" => "checkbox"
        }
      ]

      assert %{"i18n" => {:error, :no_translation_found}} =
               Parser.format_content(%{
                 content: content,
                 content_schema: schema,
                 domain_ids: [],
                 lang: "es"
               })
    end
  end

  describe "append_parsed_fields/3" do
    test "formats type url" do
      url_value = "url_value"
      fields = [%{"type" => "url", "name" => @field_name}]
      content = %{@atom_field_name => %{url_value: url_value}}

      assert Parser.append_parsed_fields([], fields, content) == [url_value]
    end

    test "formats type domain using external id by default and if specified" do
      %{id: domain_id_1} = CacheHelpers.put_domain(external_id: "domain_1_external_id")
      %{id: domain_id_2} = CacheHelpers.put_domain(external_id: "domain_2_external_id")

      fields = [%{"type" => "domain", "name" => @field_name}]
      content = %{@atom_field_name => [domain_id_1, domain_id_2]}

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
      content = %{@atom_field_name => [domain_id_1, domain_id_2]}

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

      content = %{@atom_field_name => ["1927_50", "1927_51"]}

      assert Parser.append_parsed_fields([], fields, content) == ["/#{node1_name}|/#{node2_name}"]
    end

    test "formats type system" do
      fields = [%{"type" => "system", "name" => @field_name}]
      content = %{@atom_field_name => %{name: "system"}}

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

      content = %{@atom_field_name => ["v1", "v2"]}

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

      content = %{@atom_field_name => ["v1", "v2"]}

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

      content = %{@atom_field_name => ["v1", "v2"]}

      lang = "en"

      CacheHelpers.put_i18n_message(lang, %{message_id: "fields.bar.v1", definition: "english_v1"})

      CacheHelpers.put_i18n_message(lang, %{message_id: "fields.bar.v3", definition: "english_v3"})

      assert Parser.append_parsed_fields([], fields, content, lang: lang) == ["english_v1|v2"]
    end

    test "type table is formated as empty string" do
      assert Parser.append_parsed_fields([], %{"type" => "table"}, nil) == [""]
    end

    test "field named tags is formatted" do
      fields = [%{"name" => "tags"}]
      content = %{tags: ["tag1", "tag2"]}

      assert Parser.append_parsed_fields([], fields, content) == ["tag1|tag2"]
    end

    test "formats field to string" do
      fields = [%{"name" => @field_name}]
      content = %{@atom_field_name => "value"}

      assert Parser.append_parsed_fields([], fields, content) == ["value"]
    end
  end
end
