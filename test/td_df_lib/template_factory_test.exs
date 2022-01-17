defmodule TdDfLib.TemplateFactoryTest do
  use ExUnit.Case
  use ExMachina
  use TdDfLib.TemplateFactory

  describe "build(:template_field)" do
    test "returns a map with binary keys" do
      field = build(:template_field, name: "foo", foo: "bar")
      assert Map.keys(field) == ["cardinality", "foo", "label", "name", "type", "values"]
      assert field["name"] == "foo"
    end
  end

  describe "build(:template_group)" do
    test "returns a map with binary keys" do
      group = build(:template_group, name: "foo", foo: "bar")
      assert Map.keys(group) == ["fields", "foo", "name"]
      assert group["name"] == "foo"

      group = build(:template_group, fields: [%{foo: "bar"}])
      assert group["fields"] == [%{"foo" => "bar"}]
    end
  end
end
