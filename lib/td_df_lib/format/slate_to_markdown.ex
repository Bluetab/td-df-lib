defmodule TdDfLib.Format.SlateToMarkdown do
  @moduledoc """
  Converts Slate-format rule descriptions (jsonb maps) into Markdown text.

  Supports paragraphs, headings, bulleted and numbered lists, links, and the
  `bold`, `italic`, and `underlined` marks (composable). Pure functions: no
  Ecto, no I/O.
  """

  @block_separator "\n\n"
  @whitespace_split ~r/\A(\s*)(.*?)(\s*)\z/su

  @spec convert(nil | binary() | map()) :: nil | binary()
  def convert(nil), do: nil
  def convert(text) when is_binary(text), do: text

  def convert(%{"document" => %{"nodes" => nodes}}) when is_list(nodes) do
    nodes
    |> Enum.map(&render_block/1)
    |> Enum.join(@block_separator)
  end

  def convert(_), do: ""

  defp render_block(%{"type" => "paragraph", "nodes" => nodes}), do: render_inlines(nodes)

  defp render_block(%{"type" => "heading-one", "nodes" => nodes}),
    do: "# " <> render_inlines(nodes)

  defp render_block(%{"type" => "heading-two", "nodes" => nodes}),
    do: "## " <> render_inlines(nodes)

  defp render_block(%{"type" => "bulleted-list", "nodes" => items}) do
    items
    |> Enum.map(fn item -> "- " <> render_list_item(item) end)
    |> Enum.join("\n")
  end

  defp render_block(%{"type" => "numbered-list", "nodes" => items}) do
    items
    |> Enum.with_index(1)
    |> Enum.map(fn {item, index} -> "#{index}. " <> render_list_item(item) end)
    |> Enum.join("\n")
  end

  defp render_block(%{"nodes" => nodes}), do: render_inlines(nodes)
  defp render_block(_), do: ""

  defp render_list_item(%{"nodes" => nodes}), do: render_inlines(nodes)
  defp render_list_item(_), do: ""

  defp render_inlines(nodes) when is_list(nodes),
    do: Enum.map_join(nodes, "", &render_inline/1)

  defp render_inlines(_), do: ""

  defp render_inline(%{"object" => "text", "text" => text} = node)
       when is_binary(text) and text != "" do
    apply_marks(text, mark_types(node))
  end

  defp render_inline(%{"object" => "text"}), do: ""

  defp render_inline(%{"object" => "inline", "type" => "link", "nodes" => nodes} = node) do
    href = node |> Map.get("data", %{}) |> Map.get("href", "")
    "[" <> render_inlines(nodes) <> "](" <> href <> ")"
  end

  defp render_inline(%{"nodes" => nodes}), do: render_inlines(nodes)
  defp render_inline(_), do: ""

  defp mark_types(%{"marks" => marks}) when is_list(marks) do
    marks
    |> Enum.map(&Map.get(&1, "type"))
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
  end

  defp mark_types(_), do: MapSet.new()

  defp apply_marks(text, marks) do
    {leading, core, trailing} = split_outer_whitespace(text)

    if core == "" do
      text
    else
      wrapped =
        core
        |> wrap_if(MapSet.member?(marks, "italic"), "*", "*")
        |> wrap_if(MapSet.member?(marks, "bold"), "**", "**")
        |> wrap_if(MapSet.member?(marks, "underlined"), "<u>", "</u>")

      leading <> wrapped <> trailing
    end
  end

  defp wrap_if(text, true, left, right), do: left <> text <> right
  defp wrap_if(text, false, _left, _right), do: text

  defp split_outer_whitespace(text) do
    case Regex.run(@whitespace_split, text, capture: :all_but_first) do
      [leading, core, trailing] -> {leading, core, trailing}
      _ -> {"", text, ""}
    end
  end
end
