defmodule TdDfLib.RichText do
  @moduledoc """
  Helper module to manipulate rich text.
  """

  alias TdDfLib.Format.SlateToMarkdown

  @spec to_markdown_content(nil | map()) :: nil | map()
  def to_markdown_content(nil), do: nil

  def to_markdown_content(content) when is_map(content) do
    Map.new(content, fn {k, v} -> {k, convert_field(v)} end)
  end

  defp convert_field(%{"value" => %{"document" => _} = doc} = field) do
    Map.put(field, "value", SlateToMarkdown.convert(doc))
  end

  defp convert_field(%{"value" => empty} = field) when empty == %{} do
    Map.put(field, "value", "")
  end

  defp convert_field(field), do: field

  def to_rich_text(nil), do: %{}
  def to_rich_text(""), do: %{}

  def to_rich_text(text) when is_binary(text) do
    nodes =
      text
      |> String.split("\n")
      |> Enum.map(fn text ->
        %{
          "object" => "block",
          "type" => "paragraph",
          "nodes" => [%{"object" => "text", "leaves" => [%{"text" => text}]}]
        }
      end)

    %{"document" => %{"nodes" => nodes}}
  end

  def to_plain_text(%{"document" => doc}) do
    plain_text = to_plain_text(doc)

    case String.last(plain_text) do
      " " -> String.slice(plain_text, 0..-2//1)
      _ -> plain_text
    end
  end

  def to_plain_text(%{"object" => "block", "nodes" => nodes}) do
    [to_plain_text(nodes), " "] |> Enum.join("")
  end

  def to_plain_text(%{"object" => "text", "leaves" => leaves}) do
    to_plain_text(leaves)
  end

  def to_plain_text(%{"nodes" => nodes}), do: to_plain_text(nodes)

  def to_plain_text([head | tail]) do
    [to_plain_text(head), to_plain_text(tail)] |> Enum.join("")
  end

  def to_plain_text(%{"text" => text}), do: text
  def to_plain_text(_), do: ""
end
