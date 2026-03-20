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
end
