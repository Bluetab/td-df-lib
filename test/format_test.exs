defmodule TdDfLib.FormatTest do
  use ExUnit.Case
  doctest TdDfLib.Format

  alias TdDfLib.Format

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
      %{"name" => "foo", "default" => "foo"},
      %{"name" => "bar", "cardinality" => "+", "values" => []},
      %{"name" => "baz", "cardinality" => "*", "values" => []},
      %{"name" => "bay", "type" => "enriched_text"}
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
      %{"name" => "foo", "default" => "foo"},
      %{"name" => "bar", "cardinality" => "+", "values" => []},
      %{"name" => "baz", "cardinality" => "*", "values" => []}
    ]

    assert is_nil(Format.search_values(nil, fields))
  end
end
