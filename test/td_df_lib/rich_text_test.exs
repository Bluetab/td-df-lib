defmodule TdDfLib.RichTextTest do
  use ExUnit.Case, async: true

  alias TdDfLib.RichText

  describe "to_markdown_content/1" do
    test "nil returns nil" do
      assert RichText.to_markdown_content(nil) == nil
    end

    test "empty map returns empty map" do
      assert RichText.to_markdown_content(%{}) == %{}
    end

    test "field with string value is unchanged" do
      content = %{"name" => %{"value" => "hello", "origin" => "user"}}
      assert RichText.to_markdown_content(content) == content
    end

    test "field with list value is unchanged" do
      content = %{"tags" => %{"value" => ["a", "b"], "origin" => "user"}}
      assert RichText.to_markdown_content(content) == content
    end

    test "field with number value is unchanged" do
      content = %{"score" => %{"value" => 42, "origin" => "user"}}
      assert RichText.to_markdown_content(content) == content
    end

    test "field with null value is unchanged" do
      content = %{"note" => %{"value" => nil, "origin" => "default"}}
      assert RichText.to_markdown_content(content) == content
    end

    test "field with empty-object value becomes empty string and preserves origin" do
      content = %{"description" => %{"value" => %{}, "origin" => "default"}}

      assert RichText.to_markdown_content(content) ==
               %{"description" => %{"value" => "", "origin" => "default"}}
    end

    test "field with extra keys preserves them" do
      content = %{
        "description" => %{
          "value" => %{},
          "origin" => "user",
          "extra" => "keep me"
        }
      }

      assert RichText.to_markdown_content(content) ==
               %{
                 "description" => %{
                   "value" => "",
                   "origin" => "user",
                   "extra" => "keep me"
                 }
               }
    end

    test "field with slate document becomes markdown string" do
      slate =
        document([
          block("paragraph", [text("hello "), text("world", marks: ~w(bold))])
        ])

      content = %{"description" => %{"value" => slate, "origin" => "user"}}

      assert RichText.to_markdown_content(content) ==
               %{"description" => %{"value" => "hello **world**", "origin" => "user"}}
    end

    test "field with slate document containing a link is converted" do
      slate =
        document([
          block("paragraph", [
            text("see "),
            link("https://example.com", [text("example")])
          ])
        ])

      content = %{"link" => %{"value" => slate, "origin" => "user"}}

      assert RichText.to_markdown_content(content) ==
               %{"link" => %{"value" => "see [example](https://example.com)", "origin" => "user"}}
    end

    test "mixed content only converts slate fields" do
      slate = document([block("paragraph", [text("doc")])])

      content = %{
        "name" => %{"value" => "rule one", "origin" => "user"},
        "tags" => %{"value" => ["a", "b"], "origin" => "user"},
        "description" => %{"value" => slate, "origin" => "user"},
        "notes" => %{"value" => %{}, "origin" => "default"},
        "score" => %{"value" => 7, "origin" => "user"}
      }

      assert RichText.to_markdown_content(content) == %{
               "name" => %{"value" => "rule one", "origin" => "user"},
               "tags" => %{"value" => ["a", "b"], "origin" => "user"},
               "description" => %{"value" => "doc", "origin" => "user"},
               "notes" => %{"value" => "", "origin" => "default"},
               "score" => %{"value" => 7, "origin" => "user"}
             }
    end

    test "non-wrapped fields are passed through unchanged" do
      content = %{"raw" => "loose value", "n" => 1}
      assert RichText.to_markdown_content(content) == content
    end

    test "real structure_notes/83 snapshot is converted to markdown paragraphs" do
      content = %{
        "application_json" => %{"value" => structure_notes_83_slate(), "origin" => "user"}
      }

      expected_markdown =
        ~s({\n\n\t"type":"object",\n\n\t"properties":{\n\n\t\t"isocode":{\n\n) <>
          ~s(\t\t\t"type":"string",\n\n\t\t\t"nullable":true\n\n\t\t},\n\n) <>
          ~s(\t\t"value":{\n\n\t\t\t"type":"integer",\n\n\t\t\t"format":"int32"\n\n\t\t}\n\n) <>
          ~s(\t},\n\n\t"additionalProperties":false\n\n})

      assert RichText.to_markdown_content(content) ==
               %{
                 "application_json" => %{"value" => expected_markdown, "origin" => "user"}
               }
    end
  end

  defp document(nodes), do: %{"document" => %{"nodes" => nodes}}

  defp block(type, nodes) do
    %{"object" => "block", "type" => type, "data" => %{}, "nodes" => nodes}
  end

  defp text(content, opts \\ []) do
    marks =
      opts
      |> Keyword.get(:marks, [])
      |> Enum.map(fn type -> %{"object" => "mark", "type" => type, "data" => %{}} end)

    %{"object" => "text", "text" => content, "marks" => marks}
  end

  defp link(href, nodes) do
    %{
      "object" => "inline",
      "type" => "link",
      "data" => %{"href" => href},
      "nodes" => nodes
    }
  end

  defp structure_notes_83_slate do
    lines = [
      "{",
      "\t\"type\":\"object\",",
      "\t\"properties\":{",
      "\t\t\"isocode\":{",
      "\t\t\t\"type\":\"string\",",
      "\t\t\t\"nullable\":true",
      "\t\t},",
      "\t\t\"value\":{",
      "\t\t\t\"type\":\"integer\",",
      "\t\t\t\"format\":\"int32\"",
      "\t\t}",
      "\t},",
      "\t\"additionalProperties\":false",
      "}"
    ]

    %{
      "object" => "value",
      "document" => %{
        "data" => %{},
        "object" => "document",
        "nodes" => Enum.map(lines, fn line -> block("paragraph", [text(line)]) end)
      }
    }
  end
end
