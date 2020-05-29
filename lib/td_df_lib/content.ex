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

      iex> Content.merge(nil, %{foo: 1})
      nil

      iex> Content.merge(%{foo: 1}, nil)
      %{foo: 1}

      iex> Content.merge(%{foo: ""}, %{})
      %{}

      iex> Content.merge(%{foo: ""}, %{foo: "foo", bar: "bar"})
      %{foo: "foo", bar: "bar"}

      iex> Content.merge(%{foo: "new"}, %{foo: "foo", bar: "bar"})
      %{foo: "new", bar: "bar"}

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

  @spec empty?(term()) :: boolean()
  defp empty?(term)

  defp empty?({_k, v}), do: empty?(v)
  defp empty?(nil), do: true
  defp empty?(""), do: true
  defp empty?([]), do: true
  defp empty?(%{} = v) when map_size(v) == 0, do: true
  defp empty?(_not_empty), do: false
end
