defmodule TdDfLib.Templates do
  @moduledoc """
  Provides functions for working with templates.
  """

  alias TdCache.TemplateCache
  alias TdDfLib.Format

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

  def optional_fields(nil = _template), do: []

  def subscribable_fields(template_name) when is_binary(template_name) do
    template_name
    |> TemplateCache.get_by_name!()
    |> subscribable_fields()
  end

  def subscribable_fields(%{content: content} = _template) do
    content
    |> Enum.flat_map(&Map.get(&1, "fields", []))
    |> Enum.filter(&is_subscribable?/1)
    |> Enum.map(&Map.get(&1, "name"))
  end

  def subscribable_fields(nil = _template), do: []

  def group_name(template_name, field_name) when is_binary(template_name) do
    template_name
    |> TemplateCache.get_by_name!()
    |> group_name(field_name)
  end

  def group_name(%{content: content} = _template, field_name) do
    do_group_name(content, field_name)
  end

  def content_schema(template_name) do
    case TemplateCache.get_by_name!(template_name) do
      nil ->
        {:error, :template_not_found}

      template ->
        template
        |> Map.get(:content)
        |> Format.flatten_content_fields()
    end
  end

  defp do_group_name(content, field_name) do
    content
    |> Enum.filter(&has_field?(&1, field_name))
    |> Enum.map(fn %{"name" => group} -> group end)
    |> Enum.at(0)
  end

  defp has_field?(%{"fields" => fields}, field_name) do
    fields
    |> Enum.map(&Map.get(&1, "name"))
    |> Enum.member?(field_name)
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

  defp is_subscribable?(field), do: Map.get(field, "subscribable")
end
