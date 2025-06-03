defmodule TdDfLib.I18nTest do
  use ExUnit.Case

  alias TdDfLib.I18n

  describe "get_translatable_fields/1" do
    test "returns field names for translatable widgets" do
      template = %{
        content: [
          %{
            "name" => "group_name",
            "fields" => [
              %{
                "name" => "field1",
                "widget" => "enriched_text"
              },
              %{
                "name" => "field2",
                "widget" => "string"
              },
              %{
                "name" => "field3",
                "widget" => "number"
              }
            ]
          }
        ]
      }

      assert I18n.get_translatable_fields(template) == ["field1", "field2"]
    end

    test "returns empty list when no translatable fields" do
      template = %{
        content: [
          %{
            "name" => "group_name",
            "fields" => [
              %{
                "name" => "field1",
                "widget" => "number"
              }
            ]
          }
        ]
      }

      assert I18n.get_translatable_fields(template) == []
    end

    test "returns empty list for empty content" do
      template = %{content: []}
      assert I18n.get_translatable_fields(template) == []
    end
  end

  describe "is_translatable_field?/2" do
    test "returns true when field is translatable" do
      template = %{
        content: [
          %{
            "name" => "group_name",
            "fields" => [
              %{
                "name" => "field1",
                "widget" => "string"
              }
            ]
          }
        ]
      }

      assert I18n.is_translatable_field?(template, "field1")
    end

    test "returns false when field is not translatable" do
      template = %{
        content: [
          %{
            "name" => "group_name",
            "fields" => [
              %{
                "name" => "field1",
                "widget" => "number"
              }
            ]
          }
        ]
      }

      refute I18n.is_translatable_field?(template, "field1")
    end

    test "returns false when field does not exist" do
      template = %{
        content: [
          %{
            "name" => "group_name",
            "fields" => [
              %{
                "name" => "field1",
                "widget" => "string"
              }
            ]
          }
        ]
      }

      refute I18n.is_translatable_field?(template, "field2")
    end

    test "returns false for empty content" do
      template = %{content: []}
      refute I18n.is_translatable_field?(template, "field1")
    end
  end

  describe "is_translatable_field?/1" do
    test "returns true for map with translatable widget" do
      field = %{"widget" => "string"}
      assert I18n.is_translatable_field?(field)
    end

    test "returns true for translatable textarea widget" do
      field = %{"widget" => "textarea"}
      assert I18n.is_translatable_field?(field)
    end

    test "returns true for translatable enriched_text widget" do
      field = %{"widget" => "enriched_text"}
      assert I18n.is_translatable_field?(field)
    end

    test "returns false for non-translatable widget" do
      field = %{"widget" => "number"}
      refute I18n.is_translatable_field?(field)
    end

    test "returns false for map without widget key" do
      field = %{"name" => "test"}
      refute I18n.is_translatable_field?(field)
    end
  end

  describe "get_field_locale/1" do
    setup do
      CacheHelpers.put_i18n_message("es", %{
        message_id: "foo.es",
        definition: "bar"
      })

      CacheHelpers.put_i18n_message("en", %{
        message_id: "foo.en",
        definition: "bar"
      })
    end

    test "returns base field and locale when field has valid locale suffix" do
      assert I18n.get_field_locale("field1_en") == {"field1", "en"}
    end

    test "returns original field and nil when locale is not active" do
      assert I18n.get_field_locale("field_it") == {"field_it", nil}
    end

    test "returns original field and nil when field has no locale suffix" do
      assert I18n.get_field_locale("field1") == {"field1", nil}
    end

    test "returns original field and nil for invalid locale format" do
      assert I18n.get_field_locale("field1_eng") == {"field1_eng", nil}
    end

    test "checks locale in active locales passed as option" do
      assert I18n.get_field_locale("field1_fr", active_locales: ["fr"]) == {"field1", "fr"}
    end
  end
end
