defmodule TdDfLib.Content do
  @moduledoc """
  Support for managing dynamic content
  """

  alias TdDfLib.Parser
  alias TdDfLib.Validation

  @doc """
  Merges `current_content` into `content`, after first removing empty-valued
  keys from `content`. A value is considered empty if is `nil`, the empty list
  (`[]`), the empty map (`%{}`) or the empty string (`""`).

  If `content` is `nil`, returns `nil`.

  If `current_content` is `nil`, returns `content`.

  ## Examples

      iex> Content.merge(nil, %{foo: %{"value" => 1, "origin" => "user"}})
      nil

      iex> Content.merge(%{foo: %{"value" => 1, "origin" => "user"}}, nil)
      %{foo: %{"value" => 1, "origin" => "user"}}

      iex> Content.merge(%{foo: %{"value" => "", "origin" => "user"}}, %{})
      %{}

      iex> Content.merge(%{foo: %{"value" => "", "origin" => "user"}}, %{foo: %{"value" => "foo", "origin" => "user"}, bar: %{"value" => "bar", "origin" => "user"}})
      %{foo: %{"value" => "foo", "origin" => "user"}, bar: %{"value" => "bar", "origin" => "user"}}

      iex> Content.merge(%{foo: %{"value" => "new", "origin" => "user"}}, %{foo: %{"value" => "foo", "origin" => "user"}, bar: %{"value" => "bar", "origin" => "user"}})
      %{foo: %{"value" => "new", "origin" => "user"}, bar: %{"value" => "bar", "origin" => "user"}}

  """
  @spec merge(map() | nil, map() | nil) :: map() | nil
  def merge(content, current_content)

  def merge(nil = _content, _current_content), do: nil

  def merge(content, nil = _current_content), do: content

  def merge(%{} = content, %{} = current_content) do
    content
    |> Enum.reject(&value_empty?/1)
    |> Map.new()
    |> Map.merge(current_content, fn _field, new_val, _current_val -> new_val end)
  end

  @doc """
  Processes uploaded content: prepares/merges, validates and checks if unchanged.

  `compare_content` is the content to compare against for the unchanged check.
  Pass `:skip` to skip the unchanged check.

  Returns:
  - `{:ok, merged_content}` — valid and changed
  - `{:validation, {:error, changeset_or_errors}}` — validation failed
  - `{:unchanged, true}` — valid but unchanged
  """
  def process_upload_content(
        new_content,
        content_schema,
        domain_ids,
        lang,
        existing_content,
        compare_content
      ) do
    merged_content =
      prepare_and_merge_upload_content(
        new_content,
        content_schema,
        domain_ids,
        lang,
        existing_content
      )

    with {:validation, :ok} <-
           {:validation,
            Validation.validate_content(merged_content, content_schema,
              fields: Map.keys(merged_content),
              domain_ids: domain_ids
            )},
         {:unchanged, false} <-
           {:unchanged,
            compare_content != :skip and df_content_equal?(merged_content, compare_content)} do
      {:ok, merged_content}
    end
  end

  def prepare_and_merge_upload_content(
        new_content,
        content_schema,
        domain_ids,
        lang,
        existing_content
      ) do
    field_names = Enum.map(content_schema, &Map.get(&1, "name"))

    {filtered_content, empty_fields} =
      filter_and_normalize_upload_content(new_content, field_names)

    formatted_content =
      Parser.format_content(%{
        content: filtered_content,
        content_schema: content_schema,
        domain_ids: domain_ids,
        lang: lang
      })

    empty_overrides = build_empty_overrides(empty_fields, existing_content)

    cleaned_existing =
      if empty_fields != [] and existing_content do
        Map.drop(existing_content, empty_fields)
      else
        existing_content
      end

    base_content = cleaned_existing || %{}

    formatted_content
    |> merge(base_content)
    |> Map.drop(empty_fields)
    |> Map.merge(empty_overrides)
  end

  def filter_and_normalize_upload_content(new_content, field_names) do
    new_content
    |> Map.take(field_names)
    |> Enum.reduce({%{}, []}, fn {key, value}, {acc, empty} ->
      case normalize_upload_field_value(value) do
        nil -> {acc, [key | empty]}
        normalized_value -> {Map.put(acc, key, normalized_value), empty}
      end
    end)
  end

  defp normalize_upload_field_value(%{"value" => val, "origin" => _})
       when val == "" or is_nil(val),
       do: nil

  defp normalize_upload_field_value(%{"value" => _, "origin" => _} = value), do: value

  defp normalize_upload_field_value(value) when is_map(value),
    do: Map.put(value, "origin", "file")

  defp normalize_upload_field_value(value) when value == "" or is_nil(value), do: nil

  defp normalize_upload_field_value(value), do: %{"value" => value, "origin" => "file"}

  def df_content_equal?(content_a, content_b) do
    case {content_a, content_b} do
      {nil, nil} -> true
      {%{}, nil} -> content_a == %{}
      {nil, %{}} -> content_b == %{}
      {a, b} when is_map(a) and is_map(b) -> normalize_df_content(a) == normalize_df_content(b)
      _ -> false
    end
  end

  def legacy_content_support(content, legacy_content_key, new_content_key \\ :dynamic_content) do
    dynamic_content = Map.get(content, legacy_content_key)

    legacy_content =
      if is_nil(dynamic_content) do
        nil
      else
        to_legacy(dynamic_content)
      end

    content
    |> Map.put(legacy_content_key, legacy_content)
    |> Map.put(new_content_key, dynamic_content)
  end

  def to_legacy({key, %{"value" => value}}) when is_list(value) do
    {key, Enum.map(value, &to_legacy/1)}
  end

  def to_legacy({key, %{"value" => value}}) do
    {key, value}
  end

  def to_legacy({key, value}) do
    {key, value}
  end

  def to_legacy(%{} = map) do
    Map.new(map, &to_legacy/1)
  end

  def to_legacy(other) do
    other
  end

  defp normalize_df_content(%{} = map), do: normalize_map(map)

  defp normalize_map(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, normalize_value(v)} end)
  end

  def normalize_value(v) when is_map(v) do
    case Map.get(v, "value") do
      nil ->
        v
        |> Map.drop(["origin"])
        |> normalize_map()

      inner ->
        normalize_value(inner)
    end
  end

  def normalize_value(v) when is_list(v), do: v |> Enum.map(&normalize_value/1) |> Enum.sort()
  def normalize_value(v), do: v

  defp build_empty_overrides([], _existing_content), do: %{}
  defp build_empty_overrides(_empty_fields, nil), do: %{}

  defp build_empty_overrides(empty_fields, existing_content) do
    empty_fields
    |> Enum.filter(&Map.has_key?(existing_content, &1))
    |> Map.new(fn field -> {field, %{"value" => "", "origin" => "file"}} end)
  end

  defp value_empty?({_k, %{"value" => v}}), do: value_empty?(v)
  defp value_empty?({_k, v}), do: value_empty?(v)
  defp value_empty?(nil), do: true
  defp value_empty?(""), do: true
  defp value_empty?([]), do: true
  defp value_empty?(%{} = v) when map_size(v) == 0, do: true
  defp value_empty?(_), do: false
end
