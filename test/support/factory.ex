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
end
