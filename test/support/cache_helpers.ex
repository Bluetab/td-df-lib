defmodule CacheHelpers do
  @moduledoc """
  Support creation of templates in cache
  """

  import TdDfLib.Factory
  import ExUnit.Callbacks, only: [on_exit: 1]

  alias TdCache.HierarchyCache
  alias TdCache.I18nCache
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

  def insert_hierarchy(params) do
    %{id: hierarchy_id} = hierarchy = build(:hierarchy, params)

    {:ok, _} = HierarchyCache.put(hierarchy, publish: false)
    on_exit(fn -> HierarchyCache.delete(hierarchy_id) end)
    hierarchy
  end

  def put_i18n_message(lang, params) do
    I18nCache.put(lang, params)

    on_exit(fn -> I18nCache.delete(lang) end)
  end
end
