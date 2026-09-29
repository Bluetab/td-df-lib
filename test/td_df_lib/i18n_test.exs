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
                "widget" => "markdown"
              },
              %{
                "name" => "field2",
                "widget" => "string"
              },
              %{
                "name" => "field4",
                "widget" => "markdown"
              },
              %{
                "name" => "field3",
                "widget" => "number"
              }
            ]
          }
        ]
      }

      assert I18n.get_translatable_fields(template) == ["field1", "field2", "field4"]
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

    test "returns true for translatable markdown widget" do
      field = %{"widget" => "markdown"}
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

  describe "split_i18n_params/2" do
    test "separates params with language suffixes" do
      params = %{
        "name_en" => "English Name",
        "name_es" => "Nombre en Español",
        "domain_external_id" => "test_domain"
      }

      result = I18n.split_i18n_params(params, "en", ["en", "es"])

      assert result[:params] == %{
               "name" => "English Name",
               "domain_external_id" => "test_domain"
             }

      assert result[:i18n_params] == %{
               "es" => %{"name" => "Nombre en Español"}
             }
    end

    test "keeps default language params in main params" do
      params = %{
        "name_en" => "English Name",
        "name_es" => "Nombre en Español"
      }

      result = I18n.split_i18n_params(params, "en", ["en", "es"])

      assert result[:params]["name"] == "English Name"
      assert result[:i18n_params]["es"]["name"] == "Nombre en Español"
    end

    test "handles params without language suffixes" do
      params = %{
        "domain_external_id" => "test_domain",
        "status" => "published"
      }

      result = I18n.split_i18n_params(params, "en", ["en", "es"])

      assert result[:params] == params
      assert result[:i18n_params] == %{}
    end
  end

  describe "format_content_values/3" do
    test "separates content fields with language suffixes" do
      content = %{
        "text_field_en" => %{"value" => "English value", "origin" => "file"},
        "text_field_es" => %{"value" => "Valor en español", "origin" => "file"}
      }

      result = I18n.format_content_values(content, "en", ["en", "es"])

      assert result[:content] == %{
               "text_field" => %{"value" => "English value", "origin" => "file"}
             }

      assert result[:i18n_content]["es"]["content"]["text_field"] == %{
               "value" => "Valor en español",
               "origin" => "file"
             }
    end

    test "keeps default language content in main content" do
      content = %{
        "description_en" => %{"value" => "English description", "origin" => "file"},
        "description_es" => %{"value" => "Descripción en español", "origin" => "file"}
      }

      result = I18n.format_content_values(content, "en", ["en", "es"])

      assert result[:content]["description"]["value"] == "English description"

      assert result[:i18n_content]["es"]["content"]["description"]["value"] ==
               "Descripción en español"
    end

    test "handles content without language suffixes" do
      content = %{
        "number_field" => %{"value" => 42, "origin" => "file"}
      }

      result = I18n.format_content_values(content, "en", ["en", "es"])

      assert result[:content] == content
      assert result[:i18n_content]["es"]["content"] == %{}
    end
  end

  describe "process_i18n_fields/2" do
    test "processes complete data with i18n fields" do
      data = %{
        "_sheet" => "test_sheet",
        "_row_number" => 1,
        "name_en" => "English Name",
        "name_es" => "Nombre en Español",
        "domain_external_id" => "test_domain",
        "df_content" => %{
          "text_field_en" => %{"value" => "English value", "origin" => "file"},
          "text_field_es" => %{"value" => "Valor en español", "origin" => "file"}
        }
      }

      ctx = %{
        default_lang: "en",
        active_locales: ["en", "es"]
      }

      {processed_data, i18n_content} = I18n.process_i18n_fields(data, ctx)

      # Verify processed data
      assert processed_data["_sheet"] == "test_sheet"
      assert processed_data["_row_number"] == 1
      assert processed_data["name"] == "English Name"
      assert processed_data["domain_external_id"] == "test_domain"
      assert processed_data["df_content"]["text_field"]["value"] == "English value"

      # Verify i18n content
      assert i18n_content["es"]["name"] == "Nombre en Español"
      assert i18n_content["es"]["content"]["text_field"]["value"] == "Valor en español"
    end

    test "handles data without i18n fields" do
      data = %{
        "_sheet" => "test_sheet",
        "_row_number" => 1,
        "name" => "Test Name",
        "domain_external_id" => "test_domain",
        "df_content" => %{
          "text_field" => %{"value" => "Test value", "origin" => "file"}
        }
      }

      ctx = %{
        default_lang: "en",
        active_locales: ["en", "es"]
      }

      {processed_data, i18n_content} = I18n.process_i18n_fields(data, ctx)

      assert processed_data["name"] == "Test Name"
      assert processed_data["df_content"]["text_field"]["value"] == "Test value"
      assert i18n_content["es"] == %{"content" => %{}}
    end

    test "uses default values when ctx is incomplete" do
      data = %{
        "name" => "Test Name",
        "df_content" => %{}
      }

      ctx = %{}

      {processed_data, i18n_content} = I18n.process_i18n_fields(data, ctx)

      assert processed_data["name"] == "Test Name"
      assert i18n_content == %{}
    end
  end
end
