defmodule TdDfLib.ContentTest do
  use ExUnit.Case

  alias TdDfLib.Content

  doctest Content

  describe "legacy_support/3" do
    legacy_content_key = :df_content
    new_content_key = :nondefault_key

    content = %{
      id: 1234,
      df_content: %{
        "field_1" => %{"value" => "value_1", "origin" => "user"},
        "field_2" => %{"value" => "value_1", "origin" => "user"},
        "field_3" => %{
          "value" => [%{"col" => %{"origin" => "user", "value" => "first_row"}}],
          "origin" => "user"
        }
      },
      other_field: true
    }

    assert %{
             id: 1234,
             df_content: %{
               "field_1" => "value_1",
               "field_2" => "value_1",
               "field_3" => [%{"col" => "first_row"}]
             },
             nondefault_key: %{
               "field_1" => %{"value" => "value_1", "origin" => "user"},
               "field_2" => %{"value" => "value_1", "origin" => "user"},
               "field_3" => %{
                 "value" => [%{"col" => %{"origin" => "user", "value" => "first_row"}}],
                 "origin" => "user"
               }
             },
             other_field: true
           } = Content.legacy_content_support(content, legacy_content_key, new_content_key)

    assert %{
             id: 1234,
             df_content: %{
               "field_1" => "value_1",
               "field_2" => "value_1",
               "field_3" => [%{"col" => "first_row"}]
             },
             dynamic_content: %{
               "field_1" => %{"value" => "value_1", "origin" => "user"},
               "field_2" => %{"value" => "value_1", "origin" => "user"},
               "field_3" => %{
                 "value" => [%{"col" => %{"origin" => "user", "value" => "first_row"}}],
                 "origin" => "user"
               }
             },
             other_field: true
           } = Content.legacy_content_support(content, legacy_content_key)

    test "when content does not have legacy key" do
      content = %{other: true}

      assert Content.legacy_content_support(content, :df_content) == %{
               df_content: nil,
               dynamic_content: nil,
               other: true
             }
    end

    test "with primitive values" do
      content = %{
        df_content: %{"field" => "value"}
      }

      assert Content.legacy_content_support(content, :df_content) == %{
               df_content: %{"field" => "value"},
               dynamic_content: %{"field" => "value"}
             }
    end
  end

  test "merge with non-map values" do
    content = %{"a" => "value", "b" => %{"value" => "", "origin" => "user"}}
    current = %{"a" => "old"}
    assert Content.merge(content, current) == %{"a" => "value"}
  end

  describe "df_content_equal?/2" do
    test "returns true when both arguments are nil" do
      assert Content.df_content_equal?(nil, nil) == true
    end

    test "returns true when first is empty map and second is nil" do
      assert Content.df_content_equal?(%{}, nil) == true
    end

    test "returns true when first is nil and second is empty map" do
      assert Content.df_content_equal?(nil, %{}) == true
    end

    test "returns false when first is non-empty map and second is nil" do
      assert Content.df_content_equal?(%{"a" => 1}, nil) == false
    end

    test "returns false when first is nil and second is non-empty map" do
      assert Content.df_content_equal?(nil, %{"a" => 1}) == false
    end

    test "returns true for two identical maps" do
      content = %{"foo" => "bar", "baz" => "qux"}
      assert Content.df_content_equal?(content, content) == true
    end

    test "returns true for two maps with same content but different key order" do
      a = %{"a" => 1, "b" => 2, "c" => 3}
      b = %{"c" => 3, "a" => 1, "b" => 2}
      assert Content.df_content_equal?(a, b) == true
    end

    test "returns false for two maps with different values" do
      a = %{"foo" => "bar"}
      b = %{"foo" => "baz"}
      assert Content.df_content_equal?(a, b) == false
    end

    test "returns false for two maps with different keys" do
      a = %{"foo" => "bar"}
      b = %{"other" => "bar"}
      assert Content.df_content_equal?(a, b) == false
    end

    test "returns true when maps contain same df_content with value/origin wrapper" do
      a = %{"field" => %{"value" => "text", "origin" => "user"}}
      b = %{"field" => %{"value" => "text", "origin" => "file"}}
      assert Content.df_content_equal?(a, b) == true
    end

    test "returns false when value/origin wrapped values differ" do
      a = %{"field" => %{"value" => "one", "origin" => "user"}}
      b = %{"field" => %{"value" => "two", "origin" => "user"}}
      assert Content.df_content_equal?(a, b) == false
    end

    test "returns true for nested maps with same structure" do
      a = %{"a" => %{"b" => %{"value" => "v", "origin" => "user"}}}
      b = %{"a" => %{"b" => %{"value" => "v", "origin" => "file"}}}
      assert Content.df_content_equal?(a, b) == true
    end

    test "returns true for maps containing equal lists" do
      a = %{"list" => [%{"value" => 1, "origin" => "user"}, %{"value" => 2, "origin" => "user"}]}
      b = %{"list" => [%{"value" => 1, "origin" => "file"}, %{"value" => 2, "origin" => "file"}]}
      assert Content.df_content_equal?(a, b) == true
    end

    test "returns false for maps containing lists with different values" do
      a = %{"list" => [%{"value" => 1}, %{"value" => 2}]}
      b = %{"list" => [%{"value" => 1}, %{"value" => 3}]}
      assert Content.df_content_equal?(a, b) == false
    end

    test "returns false when first argument is not nil or map" do
      assert Content.df_content_equal?("string", %{}) == false
      assert Content.df_content_equal?(123, nil) == false
    end

    test "returns false when second argument is not nil or map" do
      assert Content.df_content_equal?(%{}, "string") == false
      assert Content.df_content_equal?(nil, 123) == false
    end

    test "returns true for empty maps on both sides" do
      assert Content.df_content_equal?(%{}, %{}) == true
    end

    test "normalizes map without value key by dropping origin and comparing structure" do
      a = %{"nested" => %{"k" => "v", "origin" => "user"}}
      b = %{"nested" => %{"k" => "v", "origin" => "file"}}
      assert Content.df_content_equal?(a, b) == true
    end
  end

  describe "normalize_value/1" do
    test "returns primitive values unchanged" do
      assert Content.normalize_value("text") == "text"
      assert Content.normalize_value(42) == 42
      assert Content.normalize_value(true) == true
      assert Content.normalize_value(nil) == nil
    end

    test "recursively normalizes list elements" do
      input = [%{"value" => "a", "origin" => "user"}, %{"value" => "b", "origin" => "file"}]
      assert Content.normalize_value(input) == ["a", "b"]
    end

    test "for map with value key returns normalized inner value" do
      input = %{"value" => "inner", "origin" => "user"}
      assert Content.normalize_value(input) == "inner"
    end

    test "for map without value key drops origin and normalizes remaining map" do
      input = %{"k" => "v", "origin" => "user"}
      assert Content.normalize_value(input) == %{"k" => "v"}
    end

    test "for nested map with value key recurses until primitive" do
      input = %{"value" => %{"value" => %{"value" => "deep"}}}
      assert Content.normalize_value(input) == "deep"
    end

    test "for map with value key containing list normalizes list elements" do
      input = %{"value" => [%{"value" => 1}, %{"value" => 2}], "origin" => "user"}
      assert Content.normalize_value(input) == [1, 2]
    end

    test "for map with value key containing list with numbers normalizes list elements" do
      input = %{"value" => [2, 1], "origin" => "user"}
      assert Content.normalize_value(input) == [1, 2]
    end

    test "for map with nil value key treats as map without value and normalizes" do
      input = %{"value" => nil, "origin" => "user", "other" => "x"}
      result = Content.normalize_value(input)
      assert result == %{"other" => "x", "value" => nil}
    end
  end

  describe "merge/2" do
    test "returns nil when content is nil" do
      assert Content.merge(nil, %{"a" => %{"value" => 1, "origin" => "user"}}) == nil
    end

    test "returns content when current_content is nil" do
      content = %{"a" => %{"value" => 1, "origin" => "user"}}
      assert Content.merge(content, nil) == content
    end

    test "drops empty values from new content before merging" do
      content = %{
        "a" => %{"value" => "", "origin" => "user"},
        "b" => %{"value" => [], "origin" => "user"},
        "c" => %{"value" => %{}, "origin" => "user"},
        "d" => %{"value" => nil, "origin" => "user"},
        "e" => %{"value" => "keep", "origin" => "user"}
      }

      current = %{
        "a" => %{"value" => "old", "origin" => "user"},
        "z" => %{"value" => "z", "origin" => "user"}
      }

      assert Content.merge(content, current) == %{
               "a" => %{"value" => "old", "origin" => "user"},
               "e" => %{"value" => "keep", "origin" => "user"},
               "z" => %{"value" => "z", "origin" => "user"}
             }
    end

    test "new content overrides current_content on key collisions" do
      new_content = %{"a" => %{"value" => "new", "origin" => "user"}}

      current = %{
        "a" => %{"value" => "old", "origin" => "user"},
        "b" => %{"value" => "b", "origin" => "user"}
      }

      assert Content.merge(new_content, current) == %{
               "a" => %{"value" => "new", "origin" => "user"},
               "b" => %{"value" => "b", "origin" => "user"}
             }
    end
  end

  describe "filter_and_normalize_upload_content/2" do
    test "filters unknown fields and normalizes raw values and maps" do
      new_content = %{
        "a" => "text",
        "b" => %{"value" => "wrapped", "origin" => "user"},
        "c" => %{"value" => "", "origin" => "user"},
        "d" => %{"some" => "map"},
        "e" => %{"value" => nil, "origin" => "user"},
        "f" => nil,
        "unknown" => "ignore"
      }

      {filtered, empty_fields} =
        Content.filter_and_normalize_upload_content(new_content, ["a", "b", "c", "d", "e", "f"])

      assert filtered == %{
               "a" => %{"value" => "text", "origin" => "file"},
               "b" => %{"value" => "wrapped", "origin" => "user"},
               "d" => %{"some" => "map", "origin" => "file"}
             }

      assert Enum.sort(empty_fields) == ["c", "e", "f"]
    end

    test "treats nil and empty string as empty fields" do
      new_content = %{"a" => nil, "b" => "", "c" => %{"value" => nil, "origin" => "user"}}

      {filtered, empty_fields} =
        Content.filter_and_normalize_upload_content(new_content, ["a", "b", "c"])

      assert filtered == %{}
      assert Enum.sort(empty_fields) == ["a", "b", "c"]
    end
  end

  describe "prepare_and_merge_upload_content/5" do
    test "builds empty overrides when upload clears a previously non-empty field" do
      template_data = %{
        translations: %{},
        content_schema: [
          %{"name" => "a", "type" => "string", "cardinality" => "1", "label" => "a"},
          %{"name" => "b", "type" => "string", "cardinality" => "1", "label" => "b"}
        ]
      }

      existing_content = %{
        "a" => %{"value" => "old_a", "origin" => "user"},
        "b" => %{"value" => "old_b", "origin" => "user"}
      }

      new_content = %{
        "a" => %{"value" => "", "origin" => "user"},
        "b" => "new_b"
      }

      assert Content.prepare_and_merge_upload_content(
               new_content,
               template_data,
               [],
               "en",
               existing_content
             ) == %{
               "a" => %{"value" => "", "origin" => "file"},
               "b" => %{"value" => "new_b", "origin" => "file"}
             }
    end

    test "does not create empty override when existing content is nil" do
      template_data = %{
        translations: %{},
        content_schema: [
          %{"name" => "a", "type" => "string", "cardinality" => "1", "label" => "a"}
        ]
      }

      new_content = %{"a" => %{"value" => "", "origin" => "user"}}

      assert Content.prepare_and_merge_upload_content(
               new_content,
               template_data,
               [],
               "en",
               nil
             ) == %{}
    end

    test "translates keys using translations map before filtering" do
      template_data = %{
        translations: %{"Campo A" => "field_a", "Campo B" => "field_b"},
        content_schema: [
          %{"name" => "field_a", "type" => "string", "cardinality" => "1", "label" => "Campo A"},
          %{"name" => "field_b", "type" => "string", "cardinality" => "1", "label" => "Campo B"}
        ]
      }

      new_content = %{
        "Campo A" => "valor_a",
        "Campo B" => "valor_b"
      }

      result =
        Content.prepare_and_merge_upload_content(
          new_content,
          template_data,
          [],
          "en",
          nil
        )

      assert %{
               "field_a" => %{"value" => "valor_a", "origin" => "file"},
               "field_b" => %{"value" => "valor_b", "origin" => "file"}
             } = result
    end
  end

  describe "process_upload_content/7" do
    test "returns {:ok, merged_content} when compare_content is :skip and validation passes" do
      template_data = %{
        translations: %{},
        content_schema: [
          %{"cardinality" => "1", "label" => "a", "name" => "a", "type" => "string"}
        ]
      }

      assert {:ok, %{"a" => %{"value" => "x", "origin" => "file"}}} =
               Content.process_upload_content(%{"a" => "x"}, template_data, [], "en", nil, :skip)
    end

    test "returns {:unchanged, true} when merged_content equals compare_content" do
      template_data = %{
        translations: %{},
        content_schema: [
          %{"name" => "a", "type" => "string", "cardinality" => "1", "label" => "a"}
        ]
      }

      merged = %{"a" => %{"value" => "x", "origin" => "file"}}

      assert {:unchanged, true} =
               Content.process_upload_content(
                 %{"a" => "x"},
                 template_data,
                 [],
                 "en",
                 nil,
                 merged
               )
    end

    test "returns unchanged when upload sends empty values for fields already empty in existing content" do
      template_data = %{
        translations: %{},
        content_schema: [
          %{
            "cardinality" => "?",
            "default" => %{"origin" => "default", "value" => ""},
            "label" => "foo",
            "name" => "foo",
            "type" => "string",
            "values" => nil,
            "widget" => "string"
          },
          %{
            "cardinality" => "?",
            "default" => %{"origin" => "default", "value" => ""},
            "label" => "bar",
            "name" => "bar",
            "type" => "string",
            "values" => %{"fixed" => ["1", "2", "3"]},
            "widget" => "dropdown"
          }
        ]
      }

      existing_content = %{"foo" => %{"origin" => "file", "value" => ""}}

      assert {:unchanged, true} =
               Content.process_upload_content(
                 %{
                   "foo" => %{"origin" => "file", "value" => ""},
                   "bar" => %{"origin" => "file", "value" => ""}
                 },
                 template_data,
                 [],
                 "en",
                 existing_content,
                 existing_content
               )
    end

    test "with existing content and no empty fields" do
      template_data = %{
        translations: %{},
        content_schema: [
          %{"name" => "a", "type" => "string", "cardinality" => "1", "label" => "a"}
        ]
      }

      new_content = %{"a" => "new"}
      existing_content = %{"a" => %{"value" => "old", "origin" => "user"}}

      assert {:ok, %{"a" => %{"value" => "new", "origin" => "file"}}} =
               Content.process_upload_content(
                 new_content,
                 template_data,
                 [],
                 "en",
                 existing_content,
                 :skip
               )
    end
  end
end
