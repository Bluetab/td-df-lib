defmodule TdDfLib.ParserTest do
  use ExUnit.Case

  import TdDfLib.Factory
  alias TdDfLib.Parser

  @field_name "field_name"
  @atom_field_name String.to_atom(@field_name)

  describe "append_parsed_fields/3" do
    test "formats type url" do
      url_value = "url_value"
      fields = [%{"type" => "url", "name" => @field_name}]
      content = %{@atom_field_name => %{url_value: url_value}}

      assert Parser.append_parsed_fields([], fields, content) == [url_value]
    end

    test "formats type domain" do
      %{id: domain_id_1} = CacheHelpers.put_domain(external_id: "domain1")
      %{id: domain_id_2} = CacheHelpers.put_domain(external_id: "domain2")

      fields = [%{"type" => "domain", "name" => @field_name}]
      content = %{@atom_field_name => [domain_id_1, domain_id_2]}

      assert Parser.append_parsed_fields([], fields, content) == ["domain1|domain2"]
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
        %{"type" => "hierarchy", "name" => @field_name, "values" => %{"hierarchy" => 1927}}
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
        %{"type" => "string", "name" => @field_name, "values" => %{"fixed_tuple" => values}}
      ]

      content = %{@atom_field_name => ["v1", "v2"]}

      assert Parser.append_parsed_fields([], fields, content) == ["t1|t2"]
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
