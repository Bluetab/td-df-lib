defmodule TdDfLib.MasksTest do
  use ExUnit.Case

  alias TdDfLib.Masks

  describe "TdDfLib.Masks.mask/1" do
    test "masks using detected media type" do
      data = "data:image/jpg;foo=bar;base64," <> Enum.join(1..500)
      assert Masks.mask(data) == ["image/jpg", "foo=bar", "base64"]
    end

    test "masks undetected media encodings" do
      data = "data:" <> Enum.join(1..500)
      assert Masks.mask(data) == "[data]"
    end

    test "truncates long string values" do
      data = Enum.join(1..500)
      mask = Masks.mask(data)
      assert String.length(mask) == 255
      assert String.last(mask) == "…"
    end

    test "masks slate markup" do
      data = %{"document" => %{"foo" => "bar"}}
      assert Masks.mask(data) == "[markup]"
    end
  end
end
