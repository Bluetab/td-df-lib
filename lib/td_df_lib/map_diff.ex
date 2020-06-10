defmodule TdDfLib.MapDiff do
  @moduledoc """
  Utility module to calculate differences between maps.
  """

  @doc """
  Returns a key-wise difference between two maps, considering the value `nil` to
  be equivalent to an empty map.

  A mask may be applied to the diff values by specifying the `mask` option (a
  1-arity function).

  ## Examples

      iex> MapDiff.diff(%{foo: 1, bar: 2, baz: 3}, %{foo: 1, bar: 22, xyzzy: 3})
      %{
        added: %{xyzzy: 3},
        changed: %{bar: 22},
        removed: %{baz: 3}
      }

  """
  def diff(old, new, opts \\ [])

  def diff(nil, nil, _opts), do: %{}
  def diff(nil, %{} = content, opts), do: diff(%{}, content, opts)
  def diff(%{} = content, nil, opts), do: diff(content, %{}, opts)

  def diff(%{} = old, %{} = new, opts) do
    %{
      added: key_diff(old, new, opts[:mask]),
      removed: key_diff(new, old, opts[:mask]),
      changed: val_diff(old, new, opts[:mask])
    }
    |> Enum.reject(fn {_, map} -> map == %{} end)
    |> Map.new()
  end

  defp key_diff(%{} = old, %{} = new, mask_fn) do
    new
    |> Map.drop(Map.keys(old))
    |> to_map(mask_fn)
  end

  defp val_diff(%{} = old, %{} = new, mask_fn) do
    new
    |> Map.take(Map.keys(old))
    |> Enum.reject(fn {k, v} -> Map.get(old, k) == v end)
    |> to_map(mask_fn)
  end

  defp to_map(enumerable, nil), do: Map.new(enumerable)

  defp to_map(enumerable, f) when is_function(f, 1) do
    Map.new(enumerable, fn {k, v} -> {k, f.(v)} end)
  end
end
