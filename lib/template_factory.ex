defmodule TdDfLib.TemplateFactory do
  @moduledoc """
  An `ExMachina` factory for templates.
  """

  defmacro __using__(_opts) do
    quote do
      def template_factory(attrs) do
        %{
          name: sequence("template_name"),
          scope: "dd",
          label: sequence("template_label"),
          id: sequence(:template_id, &(&1 + 999_000)),
          updated_at: DateTime.utc_now(),
          content: [build(:template_group)]
        }
        |> merge_attributes(attrs)
      end

      def template_group_factory(attrs) do
        %{
          "name" => sequence("group_name"),
          "fields" => [
            build(:template_field, name: "string"),
            build(:template_field,
              name: "list",
              type: "list",
              values: %{"fixed" => ["one", "two", "three"]}
            )
          ]
        }
        |> merge_attributes(attrs)
      end

      def template_field_factory do
        %{
          "name" => sequence("field_name"),
          "type" => "string",
          "label" => sequence("label"),
          "values" => nil,
          "cardinality" => "1"
        }
      end
    end
  end
end
