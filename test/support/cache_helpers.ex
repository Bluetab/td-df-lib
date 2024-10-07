defmodule CacheHelpers do
  @moduledoc """
  Support creation of templates in cache
  """

  import TdDfLib.Factory
  import ExUnit.Callbacks, only: [on_exit: 1]

  alias TdCache.AclCache
  alias TdCache.HierarchyCache
  alias TdCache.I18nCache
  alias TdCache.SystemCache
  alias TdCache.TaxonomyCache
  alias TdCache.TemplateCache
  alias TdCache.UserCache

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

  def put_i18n_messages(lang, messages) when is_list(messages) do
    Enum.each(messages, &I18nCache.put(lang, &1))
    on_exit(fn -> I18nCache.delete(lang) end)
  end

  def put_i18n_message(lang, message), do: put_i18n_messages(lang, [message])

  def insert_user(params \\ %{}) do
    %{id: id} = user = build(:user, params)
    on_exit(fn -> UserCache.delete(id) end)
    {:ok, _} = UserCache.put(user)
    user
  end

  def insert_group(params \\ %{}) do
    %{id: id} = group = build(:group, params)
    on_exit(fn -> UserCache.delete_group(id) end)
    {:ok, _} = UserCache.put_group(group)
    group
  end

  def insert_acl(resource_id, role, user_ids, resource_type \\ "domain") do
    on_exit(fn ->
      AclCache.delete_acl_roles(resource_type, resource_id)
      AclCache.delete_acl_role_users(resource_type, resource_id, role)
    end)

    AclCache.set_acl_roles(resource_type, resource_id, [role])
    AclCache.set_acl_role_users(resource_type, resource_id, role, user_ids)
    :ok
  end

  def insert_group_acl(resource_id, role, group_ids, resource_type \\ "domain") do
    on_exit(fn ->
      AclCache.delete_acl_roles(resource_type, resource_id)
      AclCache.delete_acl_role_groups(resource_type, resource_id, role)
    end)

    AclCache.set_acl_group_roles(resource_type, resource_id, [role])
    AclCache.set_acl_role_groups(resource_type, resource_id, role, group_ids)
    :ok
  end
end
