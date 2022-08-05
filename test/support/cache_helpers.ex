defmodule CacheHelpers do
  @moduledoc """
  Support creation of templates in cache
  """

  import TdDfLib.Factory

  alias TdCache.TemplateCache

  def insert_template(params \\ %{}) do
    %{id: template_id} = template = build(:template, params)
    {:ok, _} = TemplateCache.put(template, publish: false)
    ExUnit.Callbacks.on_exit(fn -> TemplateCache.delete(template_id) end)
    template
  end
end
