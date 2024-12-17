defmodule TdDfLib.Templates do
  @moduledoc """
  Provides functions for working with templates.
  """

  alias TdDfLib.Format

  @templates Application.compile_env(:td_df_lib, :templates_module, TdCache.TemplateCache)

  def completeness(%{} = content, %{} = template) do
    template_completeness(template, content)
  end

  def completeness(%{} = content, template_name) when is_binary(template_name) do
    template_name
    |> @templates.get_by_name!()
    |> template_completeness(content)
  end

  def visible_fields(template_name, %{} = content) when is_binary(template_name) do
    template_name
    |> @templates.get_by_name!()
    |> visible_fields(content)
  end

  def visible_fields(%{content: template_content} = _template, %{} = content) do
    template_content
    |> Enum.flat_map(&Map.get(&1, "fields", []))
    |> Enum.filter(&visible?(&1, content))
    |> Enum.map(&Map.get(&1, "name"))
  end

  def visible_fields(nil = _template, _content), do: []

  def subscribable_fields(template_name) when is_binary(template_name) do
    template_name
    |> @templates.get_by_name!()
    |> subscribable_fields()
  end

  def subscribable_fields(%{content: content} = _template) do
    content
    |> Enum.flat_map(&Map.get(&1, "fields", []))
    |> Enum.filter(&subscribable?/1)
    |> Enum.map(&Map.get(&1, "name"))
  end

  def subscribable_fields(nil = _template), do: []

  def subscribable_fields_by_type(scope) do
    scope
    |> @templates.list_by_scope!()
    |> Enum.map(fn t -> {t.name, subscribable_fields(t)} end)
    |> Enum.reject(fn {_, v} -> Enum.empty?(v) end)
    |> Map.new()
  end

  def group_name(template_name, field_name) when is_binary(template_name) do
    template_name
    |> @templates.get_by_name!()
    |> group_name(field_name)
  end

  def group_name(%{content: content} = _template, field_name) do
    do_group_name(content, field_name)
  end

  def content_schema(template_name) do
    case @templates.get_by_name!(template_name) do
      nil ->
        {:error, :template_not_found}

      template ->
        template
        |> Map.get(:content)
        |> Format.flatten_content_fields()
    end
  end

  def content_schema_by_id(template_id) do
    case @templates.get(template_id) do
      {:ok, template} ->
        template
        |> Map.get(:content)
        |> Format.flatten_content_fields()

      nil ->
        {:error, :template_not_found}
    end
  end

  def has_ai_suggestions(template_id) do
    case @templates.get(template_id) do
      {:ok, template} ->
        template
        |> Map.get(:content)
        |> Format.flatten_content_fields()
        |> Enum.any?(fn
          %{"ai_suggestion" => ai_suggestion} -> ai_suggestion
          _ -> false
        end)

      nil ->
        {:error, :template_not_found}
    end
  end

  def suggestion_fields_for_template(template_id) do
    case @templates.get(template_id) do
      {:ok, template} ->
        template
        |> Map.get(:content)
        |> Format.flatten_content_fields()
        |> Enum.filter(& &1["ai_suggestion"])
        |> case do
          [] -> {:error, :no_ai_suggestion_fields}
          fields -> {:ok, Enum.map(fields, &map_suggestion_field/1)}
        end

      nil ->
        {:error, :template_not_found}
    end
  end

  defp map_suggestion_field(%{"values" => %{"fixed" => possible_values}} = field) do
    field
    |> Map.take(["name", "description"])
    |> Map.put("possible_values", possible_values)
  end

  defp map_suggestion_field(%{"values" => %{"fixed_tuple" => tuples}} = field) do
    possible_values = Enum.map(tuples, & &1["value"])

    field
    |> Map.take(["name", "description"])
    |> Map.put("possible_values", possible_values)
  end

  defp map_suggestion_field(field), do: Map.take(field, ["name", "description"])

  def meets_dependency?([_ | _] = value, target) do
    not MapSet.disjoint?(MapSet.new(value), MapSet.new(target))
  end

  def meets_dependency?(value, target) do
    Enum.member?(target, value)
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

  defp visible?(
         %{"depends" => %{"on" => on, "to_be" => target = [_ | _]}},
         content
       ) do
    content
    |> Map.get(on)
    |> get_field_value()
    |> meets_dependency?(target)
  end

  defp visible?(
         %{"values" => %{"switch" => %{"on" => on, "values" => %{} = target}}},
         content
       ) do
    content
    |> Map.get(on)
    |> get_field_value()
    |> meets_dependency?(Map.keys(target))
  end

  defp visible?(_, _), do: true

  defp get_field_value(%{"value" => value}), do: value
  defp get_field_value(value), do: value

  defp template_completeness(nil = _template, _content), do: 0.0

  defp template_completeness(%{} = template, content) do
    template
    |> visible_fields(content)
    |> field_completeness(content)
  end

  defp field_completeness([] = _visible_fields, _content), do: 100.0

  defp field_completeness([_ | _] = _visible_fields, %{} = content) when content == %{},
    do: 0.0

  defp field_completeness([_ | _] = visible_fields, %{} = content) do
    {completed_count, count} =
      visible_fields
      |> Enum.map(&Map.get(content, &1))
      |> Enum.map(&complete?/1)
      |> Enum.reduce({0, 0}, fn
        true, {completed_count, count} -> {completed_count + 1, count + 1}
        _, {completed_count, count} -> {completed_count, count + 1}
      end)

    Float.round(100 * completed_count / count, 2)
  end

  defp complete?(%{"value" => value, "origin" => _}), do: complete?(value)
  defp complete?(nil), do: false
  defp complete?([]), do: false
  defp complete?(%{} = value) when value == %{}, do: false

  defp complete?(value) when is_binary(value) do
    length =
      value
      |> String.trim()
      |> String.length()

    length > 0
  end

  defp complete?(_value), do: true

  defp subscribable?(field), do: Map.get(field, "subscribable")
end
