defmodule TdDfLib.MapDiff do
  @moduledoc """
  Utility module to calculate differences between maps.
  """

  @doc """
  Returns a key-wise difference between two maps, considering the value `nil` to
  be equivalent to an empty map.

  ## Examples

      iex> MapDiff.diff(%{foo: 1, bar: 2, baz: 3}, %{foo: 1, bar: 22, xyzzy: 3})
      %{
        added: %{xyzzy: 3},
        changed: %{bar: 22},
        removed: %{baz: 3}
      }

  """
  def diff(old, new)

  def diff(nil, nil), do: %{}
  def diff(nil, %{} = content), do: diff(%{}, content)
  def diff(%{} = content, nil), do: diff(content, %{})

  def diff(%{} = old, %{} = new) do
    %{
      added: key_diff(old, new),
      removed: key_diff(new, old),
      changed: val_diff(old, new)
    }
    |> Enum.reject(fn {_, map} -> map == %{} end)
    |> Map.new()
  end

  defp key_diff(%{} = old, %{} = new) do
    Map.drop(new, Map.keys(old))
  end

  defp val_diff(%{} = old, %{} = new) do
    new
    |> Map.take(Map.keys(old))
    |> Enum.reject(fn {k, v} -> Map.get(old, k) == v end)
    |> Map.new()
  end
end
