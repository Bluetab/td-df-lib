defmodule TdDfLib.Format do
  @moduledoc """
  Manages content formatting
  """

  def apply_template(%{} = content, fields) do
    field_names = Enum.map(fields, &Map.get(&1, "name"))

    content
    |> Map.take(field_names)
    |> set_default_values(fields)
  end

  def set_default_values(content, fields) do
    fields
    |> Enum.reduce(content, &set_default_value(&2, &1))
  end

  def set_default_value(content, %{"name" => name, "default" => default}) do
    Map.put_new(content, name, default)
  end

  def set_default_value(content, %{"name" => name, "cardinality" => "+"}) do
    Map.put_new(content, name, "")
  end

  def set_default_value(content, %{"name" => name, "cardinality" => "*"}) do
    Map.put_new(content, name, [""])
  end

  def set_default_value(content, %{}), do: content
end
