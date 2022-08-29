defmodule CacheHelpers do
  @moduledoc """
  Support creation of templates in cache
  """

  import TdDfLib.Factory
  import ExUnit.Callbacks, only: [on_exit: 1]

  alias TdCache.SystemCache
  alias TdCache.TaxonomyCache
  alias TdCache.TemplateCache

  def insert_template(params \\ %{}) do
    %{id: template_id} = template = build(:template, params)
    {:ok, _} = TemplateCache.put(template, publish: false)
    on_exit(fn -> TemplateCache.delete(template_id) end)
    template
  end

  def put_domain(params \\ %{}) do
    %{id: domain_id} = domain = build(:domain, params)
    on_exit(fn -> TaxonomyCache.delete_domain(domain_id, clean: true) end)
    TaxonomyCache.put_domain(domain)
    domain
  end

  def put_system do
    system = %{id: System.unique_integer([:positive]), external_id: "foo", name: "bar"}
    SystemCache.put(system)
    on_exit(fn -> SystemCache.delete(system.id) end)
    system
  end
end
