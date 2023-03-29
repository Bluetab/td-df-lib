defmodule TdDfLib.Factory do
  @moduledoc """
  An `ExMachina` factory for `TdDfLib` tests.
  """

  use ExMachina
  use TdDfLib.TemplateFactory

  def domain_factory do
    %{
      name: sequence("domain_name"),
      id: System.unique_integer([:positive]),
      external_id: sequence("domain_external_id"),
      updated_at: DateTime.utc_now(),
      parent_id: nil
    }
  end

  def hierarchy_factory(attrs) do
    %{
      id: System.unique_integer([:positive]),
      name: sequence("family_"),
      description: sequence("description_"),
      nodes: [],
      updated_at: DateTime.utc_now()
    }
    |> merge_attributes(attrs)
  end

  def node_factory(attrs) do
    name = sequence("node_")
    hierarchy_id = Map.get(attrs, :hierarchy_id, System.unique_integer([:positive]))
    node_id = Map.get(attrs, :node_id, System.unique_integer([:positive]))

    %{
      node_id: node_id,
      hierarchy_id: hierarchy_id,
      parent_id: System.unique_integer([:positive]),
      name: name,
      description: sequence("description_"),
      path: "/#{name}",
      key: "#{hierarchy_id}_#{node_id}"
    }
    |> merge_attributes(attrs)
  end
end
