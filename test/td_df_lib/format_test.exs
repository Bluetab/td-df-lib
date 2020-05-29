defmodule TdDfLib.FormatTest do
  use ExUnit.Case
  doctest TdDfLib.Format

  alias TdDfLib.Format
  alias TdDfLib.RichText

  test "set_default_value/2 has no effect if value is present in content" do
    content = %{"foo" => "bar"}
    field = %{"name" => "foo", "default" => "baz"}
    assert Format.set_default_value(content, field) == content
  end

  test "set_default_value/2 uses field default if field is absent in content" do
    content = %{}
    field = %{"name" => "foo", "default" => "baz"}
    assert Format.set_default_value(content, field) == %{"foo" => "baz"}
  end

  test "set_default_value/2 uses empty default for values fields" do
    content = %{}
    field = %{"name" => "foo", "values" => []}
    assert Format.set_default_value(content, field) == %{"foo" => ""}
  end

  test "set_default_value/2 uses empty string as default if field cardinality is '+'" do
    content = %{}
    field = %{"name" => "foo", "cardinality" => "+", "values" => []}
    assert Format.set_default_value(content, field) == %{"foo" => [""]}
  end

  test "set_default_value/2 uses list with empty string as default if field cardinality is '*'" do
    content = %{}
    field = %{"name" => "foo", "cardinality" => "*", "values" => []}
    assert Format.set_default_value(content, field) == %{"foo" => [""]}
  end

  test "set_default_values/2 sets all default values" do
    content = %{"xyzzy" => "spqr"}

    fields = [
      %{"name" => "foo", "default" => "foo"},
      %{"name" => "bar", "cardinality" => "+", "values" => []},
      %{"name" => "baz", "cardinality" => "*", "values" => []},
      %{"name" => "xyzzy", "default" => "xyzzy"}
    ]

    assert Format.set_default_values(content, fields) == %{
             "foo" => "foo",
             "bar" => [""],
             "baz" => [""],
             "xyzzy" => "spqr"
           }
  end

  test "apply_template/2 sets default values and removes redundant fields" do
    content = %{"xyzzy" => "spqr"}

    fields = [
      %{"name" => "foo", "default" => "foo"},
      %{"name" => "bar", "cardinality" => "+", "values" => []},
      %{"name" => "baz", "cardinality" => "*", "values" => []}
    ]

    assert Format.apply_template(content, fields) == %{
             "foo" => "foo",
             "bar" => [""],
             "baz" => [""]
           }
  end

  test "apply_template/2 returns nil when no template is provided" do
    content = %{"xyzzy" => "spqr"}
    assert Format.apply_template(content, nil) == %{}
  end

  test "apply_template/2 returns nil when no content is provided" do
    fields = [
      %{"name" => "foo", "default" => "foo"},
      %{"name" => "bar", "cardinality" => "+", "values" => []},
      %{"name" => "baz", "cardinality" => "*", "values" => []}
    ]

    assert Format.apply_template(nil, fields) == %{}
  end

  test "search_values/2 sets default values and removes redundant fields" do
    content = %{
      "xyzzy" => "spqr",
      "bay" => %{
        "object" => "value",
        "document" => %{
          "data" => %{},
          "nodes" => [
            %{
              "data" => %{},
              "type" => "paragraph",
              "nodes" => [
                %{
                  "text" => "My Text",
                  "marks" => [
                    %{
                      "data" => %{},
                      "type" => "bold",
                      "object" => "mark"
                    }
                  ],
                  "object" => "text"
                }
              ],
              "object" => "block"
            }
          ],
          "object" => "document"
        }
      }
    }

    fields = [
      %{
        "name" => "group",
        "fields" => [
          %{"name" => "foo", "default" => "foo"},
          %{"name" => "bar", "cardinality" => "+", "values" => []},
          %{"name" => "baz", "cardinality" => "*", "values" => []},
          %{"name" => "bay", "type" => "enriched_text"}
        ]
      }
    ]

    assert Format.search_values(content, %{content: fields}) == %{
             "foo" => "foo",
             "bar" => [""],
             "baz" => [""],
             "bay" => "My Text"
           }
  end

  test "search_values/2 returns nil when no template is provided" do
    content = %{"xyzzy" => "spqr"}
    assert is_nil(Format.search_values(content, nil))
  end

  test "search_values/2 returns nil when no content is provided" do
    fields = [
      %{
        "name" => "group",
        "fields" => [
          %{"name" => "foo", "default" => "foo"},
          %{"name" => "bar", "cardinality" => "+", "values" => []},
          %{"name" => "baz", "cardinality" => "*", "values" => []},
          %{"name" => "bay", "type" => "enriched_text"}
        ]
      }
    ]

    assert is_nil(Format.search_values(nil, fields))
  end

  test "search_values/2 omits values of type image" do
    content = %{
      "xyzzy" => "spqr",
      "foo" => %{
        "object" => "value",
        "document" => %{
          "data" => %{},
          "nodes" => [
            %{
              "data" => %{},
              "type" => "paragraph",
              "nodes" => [
                %{
                  "text" => "My Text",
                  "marks" => [
                    %{
                      "data" => %{},
                      "type" => "bold",
                      "object" => "mark"
                    }
                  ],
                  "object" => "text"
                }
              ],
              "object" => "block"
            }
          ],
          "object" => "document"
        }
      },
      "bay" => "photo code..."
    }

    fields = [
      %{
        "name" => "group",
        "fields" => [
          %{"name" => "foo", "type" => "enriched_text"},
          %{"name" => "bar", "cardinality" => "+", "values" => []},
          %{"name" => "baz", "cardinality" => "*", "values" => []},
          %{"name" => "bay", "type" => "image"}
        ]
      }
    ]

    assert Format.search_values(content, %{content: fields}) == %{
             "bar" => [""],
             "baz" => [""],
             "foo" => "My Text"
           }
  end

  test "format_field returns url wrapped" do
    formatted_value = Format.format_field(%{"content" => "https://google.es", "type" => "url"})

    assert formatted_value == [
             %{
               "url_name" => "https://google.es",
               "url_value" => "https://google.es"
             }
           ]
  end

  test "format_field of string with fixed tuple values returns value if text is provided " do
    fixed_tuples = [%{"value" => "value1", "text" => "description1"}]

    formatted_value =
      Format.format_field(%{
        "content" => "description1",
        "type" => "string",
        "values" => %{"fixed_tuple" => fixed_tuples}
      })

    assert formatted_value == ["value1"]
  end

  test "format_field of enriched_text returns wrapped enriched text" do
    formatted_value =
      Format.format_field(%{
        "content" => "some enriched text",
        "type" => "enriched_text"
      })

    assert formatted_value == RichText.to_rich_text("some enriched text")
  end

  test "flatten_content_fields will list all fields of content" do
    content = [
      %{
        "name" => "group1",
        "fields" => [
          %{"name" => "field11", "label" => "label11", "type" => "string"},
          %{"name" => "field12", "label" => "label12", "cardinality" => "+"}
        ]
      },
      %{
        "name" => "group2",
        "fields" => [
          %{"name" => "field21", "label" => "label21", "widget" => "default"},
          %{"name" => "field22", "label" => "label22", "values" => %{"fixed" => ["a", "b", "c"]}}
        ]
      }
    ]

    flat_content = Format.flatten_content_fields(content)

    expected_flat_content = [
      %{"group" => "group1", "name" => "field11", "label" => "label11", "type" => "string"},
      %{"group" => "group1", "name" => "field12", "label" => "label12", "cardinality" => "+"},
      %{"group" => "group2", "name" => "field21", "label" => "label21", "widget" => "default"},
      %{
        "group" => "group2",
        "name" => "field22",
        "label" => "label22",
        "values" => %{"fixed" => ["a", "b", "c"]}
      }
    ]

    assert flat_content == expected_flat_content
  end
end
