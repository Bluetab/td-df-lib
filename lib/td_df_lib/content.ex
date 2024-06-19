defmodule TdDfLib.Content do
  @moduledoc """
  Support for managing dynamic content
  """

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
    |> Enum.reject(&empty?/1)
    |> Map.new()
    |> Map.merge(current_content, fn _field, new_val, _current_val -> new_val end)
  end

  def legacy_content_support(content, legacy_content_key, new_content_key \\ :dynamic_content) do
    dynamic_content = Map.get(content, legacy_content_key)

    legacy_content =
      Enum.map(dynamic_content, fn {key, %{"value" => value}} -> {key, value} end)
      |> Map.new()

    content
    |> Map.put(legacy_content_key, legacy_content)
    |> Map.put(new_content_key, dynamic_content)
  end

  @spec empty?(term()) :: boolean()
  defp empty?(term)

  defp empty?({_k, %{"value" => v}}), do: empty?(v)
  defp empty?({_k, v}), do: empty?(v)
  defp empty?(nil), do: true
  defp empty?(""), do: true
  defp empty?([]), do: true
  defp empty?(%{} = v) when map_size(v) == 0, do: true
  defp empty?(_not_empty), do: false
end
