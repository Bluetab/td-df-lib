defmodule TdDfLib.ValidationTest do
  use ExUnit.Case

  import TdDfLib.Factory

  alias TdCache.TemplateCache
  alias TdDfLib.Validation

  describe "validator/1" do
    setup do
      %{id: template_id} = template = build(:template)
      TemplateCache.put(template, publish: false)

      on_exit(fn ->
        TemplateCache.delete(template_id)
      end)

      [template: template]
    end

    test "returns a validator that returns error if template is missing" do
      validator = Validation.validator("a_missing_template")

      assert is_function(validator, 2)
      assert validator.(:content, nil) == [content: :template_not_found]
      assert validator.(:content, %{}) == [content: :template_not_found]
    end

    test "returns a validator that validates dynamic content", %{template: %{name: template_name}} do
      validator = Validation.validator(template_name)
      assert is_function(validator, 2)
      assert [{:content, {"invalid content", _errors}}] = validator.(:content, %{"list" => "four"})
    end
  end
end
