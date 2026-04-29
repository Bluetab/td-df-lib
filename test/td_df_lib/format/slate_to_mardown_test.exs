defmodule TdDfLib.Format.SlateToMardownTest do
  use ExUnit.Case, async: true

  alias TdDfLib.Format.SlateToMarkdown

  describe "convert/1 fallbacks" do
    test "nil returns nil" do
      assert SlateToMarkdown.convert(nil) == nil
    end

    test "binary input is returned unchanged" do
      assert SlateToMarkdown.convert("plain text") == "plain text"
    end

    test "unrecognized map returns empty string" do
      assert SlateToMarkdown.convert(%{"unexpected" => true}) == ""
    end
  end

  describe "convert/1 paragraphs and links" do
    test "renders a paragraph with plain text and a link" do
      input =
        document([
          block("paragraph", [
            text("Hello "),
            link("https://example.com", [text("example")]),
            text("")
          ])
        ])

      assert SlateToMarkdown.convert(input) == "Hello [example](https://example.com)"
    end
  end

  describe "convert/1 marks" do
    test "renders bold" do
      input = document([block("paragraph", [text("hello", marks: ~w(bold))])])
      assert SlateToMarkdown.convert(input) == "**hello**"
    end

    test "renders italic" do
      input = document([block("paragraph", [text("hello", marks: ~w(italic))])])
      assert SlateToMarkdown.convert(input) == "*hello*"
    end

    test "renders underlined as html" do
      input = document([block("paragraph", [text("hello", marks: ~w(underlined))])])
      assert SlateToMarkdown.convert(input) == "<u>hello</u>"
    end

    test "composes bold + italic + underlined as <u>***...***</u>" do
      input =
        document([block("paragraph", [text("hi", marks: ~w(bold italic underlined))])])

      assert SlateToMarkdown.convert(input) == "<u>***hi***</u>"
    end

    test "moves trailing whitespace outside the marks" do
      input = document([block("paragraph", [text("Important: ", marks: ~w(bold))])])
      assert SlateToMarkdown.convert(input) == "**Important:** "
    end

    test "moves leading whitespace outside the marks" do
      input = document([block("paragraph", [text("  spaced", marks: ~w(italic))])])
      assert SlateToMarkdown.convert(input) == "  *spaced*"
    end

    test "skips empty marked text leaves" do
      input =
        document([
          block("paragraph", [
            text("a", marks: ~w(italic)),
            text("", marks: ~w(italic)),
            text("b", marks: ~w(italic))
          ])
        ])

      assert SlateToMarkdown.convert(input) == "*a**b*"
    end

    test "whitespace-only marked text is preserved without wrappers" do
      input = document([block("paragraph", [text("   ", marks: ~w(bold))])])
      assert SlateToMarkdown.convert(input) == "   "
    end
  end

  describe "convert/1 headings" do
    test "heading-one prefixes with # " do
      input = document([block("heading-one", [text("Title")])])
      assert SlateToMarkdown.convert(input) == "# Title"
    end

    test "heading-two prefixes with ## " do
      input = document([block("heading-two", [text("Subtitle")])])
      assert SlateToMarkdown.convert(input) == "## Subtitle"
    end
  end

  describe "convert/1 lists" do
    test "bulleted-list renders each item with - prefix" do
      input =
        document([
          block("bulleted-list", [
            list_item([text("first")]),
            list_item([text("second")])
          ])
        ])

      assert SlateToMarkdown.convert(input) == "- first\n- second"
    end

    test "numbered-list renders each item with incrementing index" do
      input =
        document([
          block("numbered-list", [
            list_item([text("first")]),
            list_item([text("second")]),
            list_item([text("third")])
          ])
        ])

      assert SlateToMarkdown.convert(input) == "1. first\n2. second\n3. third"
    end
  end

  describe "convert/1 links with marked content" do
    test "preserves marks inside the link text" do
      input =
        document([
          block("paragraph", [
            link("https://example.com", [
              text("example", marks: ~w(bold italic))
            ])
          ])
        ])

      assert SlateToMarkdown.convert(input) == "[***example***](https://example.com)"
    end
  end

  describe "convert/1 leaves format" do
    test "renders a paragraph with text node using leaves" do
      input =
        document([
          %{
            "object" => "block",
            "type" => "paragraph",
            "nodes" => [
              %{
                "object" => "text",
                "leaves" => [%{"text" => "plain text from leaves"}]
              }
            ]
          }
        ])

      assert SlateToMarkdown.convert(input) == "plain text from leaves"
    end

    test "renders leaves with marks" do
      input =
        document([
          %{
            "object" => "block",
            "type" => "paragraph",
            "nodes" => [
              %{
                "object" => "text",
                "leaves" => [
                  %{"text" => "bold", "marks" => [%{"type" => "bold"}]},
                  %{"text" => " normal"}
                ]
              }
            ]
          }
        ])

      assert SlateToMarkdown.convert(input) == "**bold** normal"
    end

    test "skips empty leaves" do
      input =
        document([
          %{
            "object" => "block",
            "type" => "paragraph",
            "nodes" => [
              %{
                "object" => "text",
                "leaves" => [%{"text" => ""}, %{"text" => "visible"}]
              }
            ]
          }
        ])

      assert SlateToMarkdown.convert(input) == "visible"
    end
  end

  describe "convert/1 multi-block document" do
    test "joins top-level blocks with a blank line" do
      input =
        document([
          block("paragraph", [text("first paragraph")]),
          block("paragraph", [text("second paragraph")])
        ])

      assert SlateToMarkdown.convert(input) == "first paragraph\n\nsecond paragraph"
    end
  end

  describe "convert/1 full example document" do
    test "renders the user-provided slate document" do
      expected =
        "This is a complex rule with link [http://localhost:8080/rules/5](http://localhost:8080/rules/5)\n\n" <>
          "**Important:** This must be successfully converted to a *markdown and link* [*google*](https://www.google.es)\n\n" <>
          "\n\n" <>
          "## *other type*\n\n" <>
          "# *what is this*\n\n" <>
          "1. *item 1*\n2. *item 2*\n\n" <>
          "- *bullet 1*\n- *bullet 2*\n- <u>*bullet 3*</u>\n- <u>***bullet***</u> \n- [<u>***google***</u>](https://www.google.es)\n\n" <>
          "# <u>***new heading***</u> \n\n" <>
          "## <u>***lower heading***</u>"

      assert SlateToMarkdown.convert(full_example()) == expected
    end
  end

  defp document(nodes), do: %{"document" => %{"nodes" => nodes}}

  defp block(type, nodes) do
    %{"object" => "block", "type" => type, "data" => %{}, "nodes" => nodes}
  end

  defp list_item(nodes), do: block("list-item", nodes)

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

  defp full_example do
    document([
      block("paragraph", [
        text("This is a complex rule with link "),
        link("http://localhost:8080/rules/5", [
          text("http://localhost:8080/rules/5")
        ]),
        text("")
      ]),
      block("paragraph", [
        text("Important: ", marks: ~w(bold)),
        text("This must be successfully converted to a "),
        text("markdown and link ", marks: ~w(italic)),
        link("https://www.google.es", [
          text("google", marks: ~w(italic))
        ]),
        text("", marks: ~w(italic))
      ]),
      block("paragraph", [
        text("", marks: ~w(italic))
      ]),
      block("heading-two", [
        text("other type", marks: ~w(italic))
      ]),
      block("heading-one", [
        text("what is this", marks: ~w(italic))
      ]),
      block("numbered-list", [
        list_item([text("item 1", marks: ~w(italic))]),
        list_item([text("item 2", marks: ~w(italic))])
      ]),
      block("bulleted-list", [
        list_item([text("bullet 1", marks: ~w(italic))]),
        list_item([text("bullet 2", marks: ~w(italic))]),
        list_item([text("bullet 3", marks: ~w(italic underlined))]),
        list_item([text("bullet ", marks: ~w(italic underlined bold))]),
        list_item([
          text("", marks: ~w(italic underlined bold)),
          link("https://www.google.es", [
            text("google", marks: ~w(italic underlined bold))
          ]),
          text("", marks: ~w(italic underlined bold))
        ])
      ]),
      block("heading-one", [
        text("new heading ", marks: ~w(italic underlined bold))
      ]),
      block("heading-two", [
        text("lower heading", marks: ~w(italic underlined bold))
      ])
    ])
  end
end
