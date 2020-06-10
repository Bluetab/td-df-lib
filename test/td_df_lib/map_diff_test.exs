defmodule TdDfLib.MapDiffTest do
  use ExUnit.Case

  alias TdDfLib.MapDiff

  doctest TdDfLib.MapDiff

  setup _context do
    map1 = %{"foo" => "foo", "bar" => "bar", "baz" => "baz"}
    map2 = %{"foo" => "foo", "bar" => "barf", "xyzzy" => "xyzzy"}
    [map1: map1, map2: map2]
  end

  describe "TdDfLib.MapDiff.diff/2" do
    test "handles nils" do
      assert MapDiff.diff(nil, nil) == %{}
    end

    test "identifies added keys", %{map1: map1, map2: map2} do
      assert %{added: ^map1} = MapDiff.diff(nil, map1)
      assert %{added: ^map2} = MapDiff.diff(nil, map2)
      assert %{added: %{"xyzzy" => "xyzzy"}} = MapDiff.diff(map1, map2)
      assert %{added: %{"baz" => "baz"}} = MapDiff.diff(map2, map1)
    end

    test "identifies removed keys", %{map1: map1, map2: map2} do
      assert %{removed: ^map1} = MapDiff.diff(map1, nil)
      assert %{removed: ^map2} = MapDiff.diff(map2, nil)
      assert %{removed: %{"baz" => "baz"}} = MapDiff.diff(map1, map2)
      assert %{removed: %{"xyzzy" => "xyzzy"}} = MapDiff.diff(map2, map1)
    end

    test "identifies changed keys", %{map1: map1, map2: map2} do
      assert %{changed: %{"bar" => "barf"}} = MapDiff.diff(map1, map2)
      assert %{changed: %{"bar" => "bar"}} = MapDiff.diff(map2, map1)
    end

    test "applies a mask to diff values", %{map1: map1, map2: map2} do
      mask_fn = fn _ -> "hidden" end
      assert %{added: %{"xyzzy" => "hidden"}} = MapDiff.diff(map1, map2, mask: mask_fn)
      assert %{changed: %{"bar" => "hidden"}} = MapDiff.diff(map1, map2, mask: mask_fn)
      assert %{changed: %{"bar" => "hidden"}} = MapDiff.diff(map2, map1, mask: mask_fn)
      assert %{removed: %{"baz" => "hidden"}} = MapDiff.diff(map1, map2, mask: mask_fn)
    end
  end
end
