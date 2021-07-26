defmodule TdDfLib.TemplatesTest do
  use ExUnit.Case
  doctest TdDfLib.Templates

  alias TdCache.TemplateCache
  alias TdDfLib.Templates

  setup _context do
    with %{id: id, name: name} = template <- test_template(),
         {:ok, _} <- TemplateCache.put(template) do
      on_exit(fn -> TemplateCache.delete(id) end)
      {:ok, template: template, template_name: name}
    end
  end

  test "optional_fields/1 returns the optional fields of a template", %{
    template_name: template_name
  } do
    optional_fields = Templates.optional_fields(template_name)
    assert Enum.count(optional_fields) == 15
  end

  test "completeness/2 returns the completeness of some content", %{template_name: template_name} do
    content = %{"texto" => "foo"}
    assert Templates.completeness(content, template_name) == Float.round(100.0 / 15.0, 2)
  end

  test "group_name/2 returns the group name of a field", %{template_name: template_name} do
    assert Templates.group_name(template_name, "linked_dropdown") == "Lists"
  end

  test "content_schema/2 returns the content schema of a template", %{
    template_name: template_name
  } do
    assert [_ | _] = fields = Templates.content_schema(template_name)
    assert Enum.count(fields) == 18
  end

  test "subscribable_fields/1 returns subscribable fields", %{
    template_name: template_name,
    template: template
  } do
    assert ["lista_dropdown"] = Templates.subscribable_fields(template_name)
    assert ["lista_dropdown"] = Templates.subscribable_fields(template)
  end

  test "subscribable_fields_by_type/1 returns subscribable fields grouped by type", %{
    template: %{name: name, scope: scope}
  } do
    %{^name => ["lista_dropdown"]} = Templates.subscribable_fields_by_type(scope)
  end

  defp test_template do
    id = System.unique_integer([:positive])

    %{
      id: id,
      name: "Template #{id}",
      label: "Label #{id}",
      scope: "test",
      updated_at: DateTime.utc_now(),
      content: [
        %{
          "fields" => [
            %{
              "cardinality" => "?",
              "default" => "Elemento11",
              "label" => "Lista con desplegable",
              "name" => "lista_dropdown",
              "type" => "string",
              "values" => %{
                "fixed" => [
                  "Elemento1",
                  "Elemento2",
                  "Elemento3",
                  "Elemento4",
                  "Elemento5",
                  "Elemento6",
                  "Elemento7",
                  "Elemento8",
                  "Elemento9",
                  "Elemento10",
                  "Elemento11",
                  "Elemento12"
                ]
              },
              "subscribable" => true,
              "widget" => "dropdown"
            },
            %{
              "cardinality" => "?",
              "label" => "Lista enlazada",
              "name" => "linked_dropdown",
              "type" => "string",
              "values" => %{
                "switch" => %{
                  "on" => "lista_dropdown",
                  "values" => %{
                    "Elemento1" => [
                      "Elemento1.1",
                      "Elemento1.2",
                      "Elemento1.4",
                      "Elemento1.6"
                    ],
                    "Elemento2" => ["Elemento2.1", "Elemento2.3", "Elemento2.5"],
                    "Elemento3" => [
                      "Elemento3.1",
                      "Elemento3.2",
                      "Elemento3.3",
                      "Elemento3.5",
                      "Elemento3.7"
                    ],
                    "Elemento4" => [
                      "Elemento4.1",
                      "Elemento4.9",
                      "Elemento4.2",
                      "Elemento4.3",
                      "Elemento4.5",
                      "Elemento4.8",
                      "Elemento4.13"
                    ]
                  }
                }
              },
              "widget" => "dropdown"
            },
            %{
              "cardinality" => "*",
              "depends" => %{"on" => "lista_dropdown", "to_be" => ["Elemento3"]},
              "label" => "Selección múltiple",
              "name" => "dropdown_multiple",
              "type" => "string",
              "values" => %{
                "fixed" => [
                  "Elemento1",
                  "Elemento2",
                  "Elemento3",
                  "Elemento4",
                  "Elemento5",
                  "Elemento6",
                  "Elemento7",
                  "Elemento8",
                  "Elemento9",
                  "Elemento10",
                  "Elemento11",
                  "Elemento12"
                ]
              },
              "widget" => "dropdown"
            },
            %{
              "cardinality" => "?",
              "label" => "Lista con radio button",
              "name" => "lista_radio",
              "type" => "string",
              "values" => %{"fixed" => ["Si", "No", "Quiza"]},
              "widget" => "radio"
            },
            %{
              "cardinality" => "1",
              "depends" => %{"on" => "lista_radio", "to_be" => ["Si, Quiza", "Si"]},
              "label" => "Campo texto dependiente",
              "name" => "texto_dependiente",
              "type" => "string",
              "widget" => "string"
            },
            %{
              "cardinality" => "+",
              "depends" => %{"on" => "lista_radio", "to_be" => ["Si", "Quiza"]},
              "label" => "Campo lista dependiente",
              "name" => "lista_dependiente",
              "type" => "string",
              "values" => %{
                "fixed" => [
                  "Elemento1",
                  "Elemento2",
                  "Elemento3",
                  "Elemento4",
                  "Elemento5",
                  "Elemento6",
                  "Elemento7",
                  "Elemento8",
                  "Elemento9",
                  "Elemento10",
                  "Elemento11",
                  "Elemento12"
                ]
              },
              "widget" => "dropdown"
            },
            %{
              "cardinality" => "?",
              "default" => "",
              "label" => "Nuevo Campo filtrable demo",
              "name" => "demo.filter",
              "type" => "string",
              "values" => %{"fixed" => ["a", "b", "c", "d", "e"]},
              "widget" => "dropdown"
            },
            %{
              "cardinality" => "?",
              "default" => "",
              "label" => "Lista de usuarios",
              "name" => "data_owner",
              "type" => "user",
              "values" => %{"processed_users" => [], "role_users" => "Data Owner"},
              "widget" => "dropdown"
            }
          ],
          "is_secret" => false,
          "name" => "Lists"
        },
        %{
          "fields" => [
            %{
              "cardinality" => "*",
              "label" => "Urls",
              "name" => "urls",
              "type" => "url",
              "widget" => "pair_list"
            },
            %{
              "cardinality" => "*",
              "label" => "Urls One Or None",
              "name" => "urls_one_or_none",
              "type" => "url",
              "values" => nil,
              "widget" => "pair_list"
            },
            %{
              "cardinality" => "*",
              "default" => "",
              "label" => "Tabla",
              "name" => "table_field",
              "type" => "table",
              "values" => %{
                "table_columns" => [
                  %{"mandatory" => false, "name" => "Columna1"},
                  %{"mandatory" => false, "name" => "Columna2"},
                  %{"mandatory" => false, "name" => "Columna3"}
                ]
              },
              "widget" => "table"
            }
          ],
          "is_secret" => false,
          "name" => "Others"
        },
        %{
          "fields" => [
            %{
              "cardinality" => "?",
              "default" => "No",
              "label" => "Confidencial",
              "name" => "_confidential",
              "type" => "string",
              "widget" => "checkbox"
            },
            %{
              "cardinality" => "*",
              "label" => "Clave valor",
              "name" => "key_value",
              "type" => "string",
              "values" => %{
                "fixed_tuple" => [
                  %{"text" => "Elemento 1", "value" => "1"},
                  %{"text" => "Elemento 2", "value" => "2"},
                  %{"text" => "Elemento 3", "value" => "3"},
                  %{"text" => "Elemento 4", "value" => "4"}
                ]
              },
              "widget" => "dropdown"
            }
          ],
          "is_secret" => false,
          "name" => "Special Fields"
        },
        %{
          "fields" => [
            %{
              "cardinality" => "?",
              "label" => "Texto",
              "name" => "texto",
              "type" => "string",
              "widget" => "string"
            },
            %{
              "cardinality" => "*",
              "label" => "Texto múltiple",
              "name" => "texto_multiple",
              "type" => "string",
              "widget" => "string"
            },
            %{
              "cardinality" => "1",
              "label" => "Área de texto",
              "name" => "area_texto",
              "type" => "string",
              "widget" => "textarea"
            },
            %{
              "cardinality" => "?",
              "label" => "Texto Enriquecido",
              "name" => "enriched_text",
              "type" => "enriched_text",
              "widget" => "enriched_text"
            },
            %{
              "cardinality" => "?",
              "label" => "Password",
              "name" => "pass",
              "type" => "string",
              "widget" => "password"
            }
          ],
          "is_secret" => false,
          "name" => "Textos"
        }
      ]
    }
  end
end
