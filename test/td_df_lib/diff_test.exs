defmodule TdDfLib.DiffTest do
  use ExUnit.Case

  alias TdDfLib.Diff

  doctest TdDfLib.Diff

  setup _context do
    map1 = %{"foo" => "foo", "bar" => "bar", "baz" => "baz"}
    map2 = %{"foo" => "foo", "bar" => "barf", "xyzzy" => "xyzzy"}
    [map1: map1, map2: map2]
  end

  describe "TdDfLib.Diff.diff/2" do
    test "handles nils" do
      assert Diff.diff(nil, nil) == %{}
    end

    test "identifies added keys", %{map1: map1, map2: map2} do
      assert %{added: ["bar", "baz", "foo"]} = Diff.diff(nil, map1)
      assert %{added: ["bar", "foo", "xyzzy"]} = Diff.diff(nil, map2)
      assert %{added: ["xyzzy"]} = Diff.diff(map1, map2)
      assert %{added: ["baz"]} = Diff.diff(map2, map1)
    end

    test "identifies removed keys", %{map1: map1, map2: map2} do
      assert %{removed: ["bar", "baz", "foo"]} = Diff.diff(map1, nil)
      assert %{removed: ["bar", "foo", "xyzzy"]} = Diff.diff(map2, nil)
      assert %{removed: ["baz"]} = Diff.diff(map1, map2)
      assert %{removed: ["xyzzy"]} = Diff.diff(map2, map1)
    end

    test "identifies changed keys", %{map1: map1, map2: map2} do
      assert %{changed: ["bar"]} = Diff.diff(map1, map2)
      assert %{changed: ["bar"]} = Diff.diff(map2, map1)
    end
  end
end
