defmodule TdDfLib.FactoryTest do
  use ExUnit.Case

  import TdDfLib.Factory

  describe "template_factory" do
    test "generates a realistic template" do
      template = build(:template)

      assert %{content: [group]} = template
      assert %{"fields" => [field | _]} = group
      assert %{"cardinality" => _, "name" => _, "label" => _, "type" => _} = field
    end
  end
end
