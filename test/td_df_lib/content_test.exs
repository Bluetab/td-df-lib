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
end
