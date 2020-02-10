defmodule TdDfLib.Templates do
  @moduledoc """
  Provides functions for working with templates. 
  """

  alias TdCache.TemplateCache

  def completeness(%{} = content, %{} = template) do
    template_completeness(template, content)
  end

  def completeness(%{} = content, template_name) when is_binary(template_name) do
    template_name
    |> TemplateCache.get_by_name!()
    |> template_completeness(content)
  end

  def optional_fields(template_name) when is_binary(template_name) do
    template_name
    |> TemplateCache.get_by_name!()
    |> optional_fields()
  end

  def optional_fields(%{content: content} = _template) do
    content
    |> Enum.flat_map(&Map.get(&1, "fields", []))
    |> Enum.filter(&is_optional?/1)
    |> Enum.map(&Map.get(&1, "name"))
  end

  defp is_optional?(%{"cardinality" => cardinality}), do: is_optional?(cardinality)
  defp is_optional?("*"), do: true
  defp is_optional?("?"), do: true
  defp is_optional?(_), do: false

  defp template_completeness(nil = _template, _content), do: 0.0

  defp template_completeness(%{} = template, content) do
    template
    |> optional_fields()
    |> field_completeness(content)
  end

  defp field_completeness([] = _optional_fields, _content), do: 100.0

  defp field_completeness([_ | _] = _optional_fields, %{} = content) when content == %{}, do: 0.0

  defp field_completeness([_ | _] = optional_fields, %{} = content) do
    {completed_count, count} =
      optional_fields
      |> Enum.map(&Map.get(content, &1))
      |> Enum.map(&is_complete?/1)
      |> Enum.reduce({0, 0}, fn
        true, {completed_count, count} -> {completed_count + 1, count + 1}
        _, {completed_count, count} -> {completed_count, count + 1}
      end)

    Float.round(100 * completed_count / count, 2)
  end

  defp is_complete?(nil), do: false
  defp is_complete?([]), do: false
  defp is_complete?(%{} = value) when value == %{}, do: false

  defp is_complete?(value) when is_binary(value) do
    length =
      value
      |> String.trim()
      |> String.length()

    length > 0
  end

  defp is_complete?(_value), do: true
end
