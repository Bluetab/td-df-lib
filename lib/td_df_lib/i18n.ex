defmodule TdDfLib.I18n do
  @moduledoc """
  Manages content formatting
  """

  alias TdDfLib.Format

  @translatable_widgets ~w(enriched_text string textarea)

  def get_translatable_fields(template) do
    template
    |> Map.get(:content)
    |> Format.flatten_content_fields()
    |> Enum.filter(&(&1["widget"] in @translatable_widgets))
    |> Enum.map(& &1["name"])
  end

  def is_translatable_field?(template = %{}, field) when is_binary(field) do
    template
    |> Map.get(:content)
    |> Format.flatten_content_fields()
    |> Enum.any?(fn field_map ->
      field_map["name"] == field and field_map["widget"] in @translatable_widgets
    end)
  end

  def is_translatable_field?(field) when is_map(field),
    do: field["widget"] in @translatable_widgets
end
