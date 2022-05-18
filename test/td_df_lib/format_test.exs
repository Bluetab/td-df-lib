defmodule TdDfLib.FormatTest do
  use ExUnit.Case
  doctest TdDfLib.Format

  alias TdCache.DomainCache
  alias TdCache.Redix
  alias TdCache.SystemCache
  alias TdDfLib.Format
  alias TdDfLib.RichText

  describe "create_changeset/2" do
    setup do
      identifier_name = "identifier"

      with_identifier = %{
        id: System.unique_integer([:positive]),
        name: "Ingesta template with identifier field",
        label: "ingesta_with_identifier",
        scope: "ie",
        content: [
          %{
            "fields" => [
              %{
                "cardinality" => "1",
                "default" => "",
                "label" => "Identifier",
                "name" => identifier_name,
                "subscribable" => false,
                "type" => "string",
                "values" => nil,
                "widget" => "identifier"
              },
              %{
                "cardinality" => "1",
                "default" => "",
                "label" => "Text",
                "name" => "text",
                "subscribable" => false,
                "type" => "string",
                "values" => nil,
                "widget" => "text"
              }
            ],
            "name" => ""
          }
        ]
      }

      without_identifier = %{
        id: System.unique_integer([:positive]),
        name: "Ingesta template without identifier field",
        label: "ingesta_without_identifier",
        scope: "ie",
        content: [
          %{
            "fields" => [
              %{
                "cardinality" => "1",
                "default" => "",
                "label" => "Text",
                "name" => "text",
                "subscribable" => false,
                "type" => "string",
                "values" => nil,
                "widget" => "text"
              }
            ],
            "name" => ""
          }
        ]
      }

      with_multifields = %{
        id: System.unique_integer([:positive]),
        name: "Ingesta template with multiple fields option",
        label: "ingesta_with_multifields",
        scope: "ie",
        content: [
          %{
            "fields" => [
              %{
                "cardinality" => "*",
                "default" => "",
                "label" => "Text",
                "name" => "text",
                "subscribable" => false,
                "type" => "string",
                "values" => nil,
                "widget" => "text"
              }
            ],
            "name" => ""
          }
        ]
      }

      template_with_identifier = CacheHelpers.insert_template(with_identifier)
      template_without_identifier = CacheHelpers.insert_template(without_identifier)
      template_with_multifields = CacheHelpers.insert_template(with_multifields)

      [
        template_with_identifier: template_with_identifier,
        template_without_identifier: template_without_identifier,
        template_with_multifields: template_with_multifields,
        identifier_name: identifier_name
      ]
    end

    test "keeps an already present identifier", %{
      template_with_identifier: template_with_identifier,
      identifier_name: identifier_name
    } do
      old_content = %{identifier_name => "1234"}
      changeset_content = %{}

      assert %{^identifier_name => "1234"} =
               Format.maybe_put_identifier(
                 changeset_content,
                 old_content,
                 template_with_identifier.name
               )
    end

    test "puts a new identifier if the template has an identifier field", %{
      template_with_identifier: template_with_identifier,
      identifier_name: identifier_name
    } do
      assert %{^identifier_name => _identifier} =
               Format.maybe_put_identifier(%{}, %{}, template_with_identifier.name)
    end

    test "avoids putting new identifier if template lacks an identifier field", %{
      template_without_identifier: template_without_identifier,
      identifier_name: identifier_name
    } do
      refute match?(
               %{^identifier_name => _identifier},
               Format.maybe_put_identifier(%{}, %{}, template_without_identifier.name)
             )
    end
  end

  test "set_default_value/2 has no effect if value is present in content" do
    content = %{"foo" => "bar"}
    field = %{"name" => "foo", "default" => "baz"}
    assert Format.set_default_value(content, field) == content
  end

  test "set_default_value/2 uses field default if field is absent in content" do
    content = %{}
    field = %{"name" => "foo", "default" => "baz"}
    assert Format.set_default_value(content, field) == %{"foo" => "baz"}
  end

  test "set_default_value/2 uses empty default for values fields" do
    content = %{}
    field = %{"name" => "foo", "values" => []}
    assert Format.set_default_value(content, field) == %{"foo" => ""}
  end

  test "set_default_value/2 uses empty string as default if field cardinality is '+'" do
    content = %{}
    field = %{"name" => "foo", "cardinality" => "+", "values" => []}
    assert Format.set_default_value(content, field) == %{"foo" => [""]}
  end

  test "set_default_value/2 uses list with empty string as default if field cardinality is '*'" do
    content = %{}
    field = %{"name" => "foo", "cardinality" => "*", "values" => []}
    assert Format.set_default_value(content, field) == %{"foo" => [""]}
  end

  test "set_default_values/2 sets all default values" do
    content = %{"xyzzy" => "spqr"}

    fields = [
      %{"name" => "foo", "default" => "foo"},
      %{"name" => "bar", "cardinality" => "+", "values" => []},
      %{"name" => "baz", "cardinality" => "*", "values" => []},
      %{"name" => "xyzzy", "default" => "xyzzy"}
    ]

    assert Format.set_default_values(content, fields) == %{
             "foo" => "foo",
             "bar" => [""],
             "baz" => [""],
             "xyzzy" => "spqr"
           }
  end

  test "set_default_values/2 sets default values for switch" do
    content = %{"xyzzy" => "spqr", "bar" => "1"}

    fields = [
      %{"name" => "foo", "default" => "foo"},
      %{"name" => "bar", "cardinality" => "?", "values" => %{"fixed" => ["1", "2", "3"]}},
      %{
        "name" => "baz",
        "cardinality" => "+",
        "default" => %{"1" => ["a"], "2" => ["c"]},
        "values" => %{
          "switch" => %{"on" => "bar", "values" => %{"1" => ["a", "b"], "2" => ["b", "c", "d"]}}
        }
      },
      %{
        "name" => "xyz",
        "cardinality" => "?",
        "default" => %{"1" => "b", "2" => "d"},
        "values" => %{
          "switch" => %{"on" => "bar", "values" => %{"1" => ["a", "b"], "2" => ["b", "c", "d"]}}
        }
      },
      %{"name" => "xyzzy", "default" => "xyzzy"}
    ]

    assert Format.set_default_values(content, fields) == %{
             "foo" => "foo",
             "bar" => "1",
             "baz" => ["a"],
             "xyz" => "b",
             "xyzzy" => "spqr"
           }

    content = %{"xyzzy" => "spqr", "bar" => "2"}

    assert Format.set_default_values(content, fields) == %{
             "foo" => "foo",
             "bar" => "2",
             "baz" => ["c"],
             "xyz" => "d",
             "xyzzy" => "spqr"
           }

    content = %{"xyzzy" => "spqr", "bar" => "3"}

    assert Format.set_default_values(content, fields) == %{
             "foo" => "foo",
             "bar" => "3",
             "baz" => [""],
             "xyz" => "",
             "xyzzy" => "spqr"
           }

    content = %{"xyzzy" => "spqr"}

    assert Format.set_default_values(content, fields) == %{
             "foo" => "foo",
             "bar" => "",
             "baz" => [""],
             "xyz" => "",
             "xyzzy" => "spqr"
           }
  end

  test "set_default_values/2 domain dependent field" do
    content = %{"xyzzy" => "spqr"}

    fields = [
      %{"name" => "foo", "default" => "foo"},
      %{
        "name" => "bar",
        "cardinality" => "+",
        "default" => %{"1" => ["a"], "2" => ["f"]},
        "values" => %{
          "domain" => %{"1" => ["a", "b", "c"], "2" => ["d", "e", "f"]}
        }
      },
      %{
        "name" => "xyz",
        "cardinality" => "?",
        "default" => %{"2" => "b", "5" => "d"},
        "values" => %{
          "domain" => %{"2" => ["i", "b"], "5" => ["d", "p"]}
        }
      },
      %{"name" => "xyzzy", "default" => "xyzzy"}
    ]

    assert Format.set_default_values(content, fields) == %{
             "foo" => "foo",
             "bar" => [""],
             "xyzzy" => "spqr",
             "xyz" => ""
           }

    assert Format.set_default_values(content, fields, domain_id: 1) == %{
             "foo" => "foo",
             "bar" => ["a"],
             "xyzzy" => "spqr",
             "xyz" => ""
           }

    assert Format.set_default_values(content, fields, domain_id: 2) == %{
             "foo" => "foo",
             "bar" => ["f"],
             "xyzzy" => "spqr",
             "xyz" => "b"
           }

    assert Format.set_default_values(content, fields, domain_id: 5) == %{
             "foo" => "foo",
             "bar" => [""],
             "xyzzy" => "spqr",
             "xyz" => "d"
           }
  end

  test "apply_template/2 sets default values and removes redundant fields" do
    content = %{"xyzzy" => "spqr"}

    fields = [
      %{"name" => "foo", "default" => "foo"},
      %{"name" => "bar", "cardinality" => "+", "values" => []},
      %{"name" => "baz", "cardinality" => "*", "values" => []}
    ]

    assert Format.apply_template(content, fields) == %{
             "foo" => "foo",
             "bar" => [""],
             "baz" => [""]
           }
  end

  test "apply_template/2 sets default values of switch like fields" do
    content = %{"xyzzy" => "spqr", "bar" => "1"}

    fields = [
      %{"name" => "foo", "default" => "foo"},
      %{"name" => "bar", "cardinality" => "?", "values" => %{"fixed" => ["1", "2", "3"]}},
      %{
        "name" => "baz",
        "cardinality" => "+",
        "default" => %{"1" => ["a"], "2" => ["c"]},
        "values" => %{
          "switch" => %{"on" => "bar", "values" => %{"1" => ["a", "b"], "2" => ["b", "c", "d"]}}
        }
      },
      %{
        "name" => "xyz",
        "cardinality" => "?",
        "default" => %{"1" => "b", "2" => "d"},
        "values" => %{
          "switch" => %{"on" => "bar", "values" => %{"1" => ["a", "b"], "2" => ["b", "c", "d"]}}
        }
      },
      %{"name" => "xyzzy", "default" => "xyzzy"}
    ]

    assert Format.apply_template(content, fields) == %{
             "foo" => "foo",
             "bar" => "1",
             "baz" => ["a"],
             "xyz" => "b",
             "xyzzy" => "spqr"
           }

    content = %{"xyzzy" => "spqr", "bar" => "2"}

    assert Format.apply_template(content, fields) == %{
             "foo" => "foo",
             "bar" => "2",
             "baz" => ["c"],
             "xyz" => "d",
             "xyzzy" => "spqr"
           }

    content = %{"xyzzy" => "spqr", "bar" => "3"}

    assert Format.apply_template(content, fields) == %{
             "foo" => "foo",
             "bar" => "3",
             "baz" => [""],
             "xyz" => "",
             "xyzzy" => "spqr"
           }

    content = %{"xyzzy" => "spqr"}

    assert Format.apply_template(content, fields) == %{
             "foo" => "foo",
             "bar" => "",
             "baz" => [""],
             "xyz" => "",
             "xyzzy" => "spqr"
           }
  end

  test "apply_template/2 sets default values of domain dependent field" do
    content = %{"xyzzy" => "spqr"}

    fields = [
      %{"name" => "foo", "default" => "foo"},
      %{
        "name" => "bar",
        "cardinality" => "+",
        "default" => %{"1" => ["a"], "2" => ["f"]},
        "values" => %{
          "domain" => %{"1" => ["a", "b", "c"], "2" => ["d", "e", "f"]}
        }
      },
      %{
        "name" => "xyz",
        "cardinality" => "?",
        "default" => %{"2" => "b", "5" => "d"},
        "values" => %{
          "domain" => %{"2" => ["i", "b"], "5" => ["d", "p"]}
        }
      },
      %{"name" => "xyzzy", "default" => "xyzzy"}
    ]

    assert Format.apply_template(content, fields) == %{
             "foo" => "foo",
             "bar" => [""],
             "xyzzy" => "spqr",
             "xyz" => ""
           }

    assert Format.apply_template(content, fields, domain_id: 1) == %{
             "foo" => "foo",
             "bar" => ["a"],
             "xyzzy" => "spqr",
             "xyz" => ""
           }

    assert Format.apply_template(content, fields, domain_id: 2) == %{
             "foo" => "foo",
             "bar" => ["f"],
             "xyzzy" => "spqr",
             "xyz" => "b"
           }

    assert Format.apply_template(content, fields, domain_id: 5) == %{
             "foo" => "foo",
             "bar" => [""],
             "xyzzy" => "spqr",
             "xyz" => "d"
           }

    assert Format.apply_template(content, fields, domain_ids: [1, 2, 5]) == %{
             "foo" => "foo",
             "bar" => ["a"],
             "xyzzy" => "spqr",
             "xyz" => "b"
           }
  end

  test "set_default_values/2 sets default values for dependent values" do
    content = %{"bar" => "1", "foo" => "6"}

    fields = [
      %{"name" => "foo", "cardinality" => "?", "values" => %{"fixed" => ["6", "7", "8"]}},
      %{"name" => "bar", "cardinality" => "?", "values" => %{"fixed" => ["1", "2", "3"]}},
      %{
        "name" => "baz",
        "cardinality" => "+",
        "depends" => %{"on" => "foo", "to_be" => ["7", "8"]},
        "default" => %{"1" => ["a"], "2" => ["c"]},
        "values" => %{
          "switch" => %{"on" => "bar", "values" => %{"1" => ["a", "b"], "2" => ["b", "c", "d"]}}
        }
      },
      %{
        "name" => "xyz",
        "cardinality" => "?",
        "depends" => %{"on" => "foo", "to_be" => ["6", "7"]},
        "default" => %{"1" => "b", "2" => "d"},
        "values" => %{
          "switch" => %{"on" => "bar", "values" => %{"1" => ["a", "b"], "2" => ["b", "c", "d"]}}
        }
      }
    ]

    assert Format.set_default_values(content, fields) == %{
             "foo" => "6",
             "bar" => "1",
             "xyz" => "b"
           }

    content = %{"bar" => "1", "foo" => "7"}

    assert Format.set_default_values(content, fields) == %{
             "foo" => "7",
             "bar" => "1",
             "baz" => ["a"],
             "xyz" => "b"
           }

    content = %{"bar" => "2", "foo" => "8"}

    assert Format.set_default_values(content, fields) == %{
             "foo" => "8",
             "bar" => "2",
             "baz" => ["c"]
           }
  end

  test "apply_template/2 returns nil when no template is provided" do
    content = %{"xyzzy" => "spqr"}
    assert Format.apply_template(content, nil) == %{}
  end

  test "apply_template/2 returns nil when no content is provided" do
    fields = [
      %{"name" => "foo", "default" => "foo"},
      %{"name" => "bar", "cardinality" => "+", "values" => []},
      %{"name" => "baz", "cardinality" => "*", "values" => []}
    ]

    assert Format.apply_template(nil, fields) == %{}
  end

  test "format_field returns url wrapped" do
    formatted_value = Format.format_field(%{"content" => "https://google.es", "type" => "url"})

    assert formatted_value == [
             %{
               "url_name" => "https://google.es",
               "url_value" => "https://google.es"
             }
           ]
  end

  test "format_field of string with fixed tuple values returns value if text is provided " do
    fixed_tuples = [%{"value" => "value1", "text" => "description1"}]

    formatted_value =
      Format.format_field(%{
        "content" => "description1",
        "type" => "string",
        "values" => %{"fixed_tuple" => fixed_tuples}
      })

    assert formatted_value == ["value1"]
  end

  test "format_field of enriched_text returns wrapped enriched text" do
    formatted_value =
      Format.format_field(%{
        "content" => "some enriched text",
        "type" => "enriched_text"
      })

    assert formatted_value == RichText.to_rich_text("some enriched text")
  end

  test "format_field of user type field" do
    assert ["foo"] ==
             Format.format_field(%{"content" => "foo", "type" => "user", "cardinality" => "+"})

    assert ["bar"] ==
             Format.format_field(%{"content" => ["bar"], "type" => "user", "cardinality" => "+"})

    assert "bar" ==
             Format.format_field(%{"content" => "bar", "type" => "user", "cardinality" => "1"})
  end

  test "format_field of string type with multiple fields" do
    assert ["foo"] ==
             Format.format_field(%{"content" => "foo", "type" => "string", "cardinality" => "+"})

    assert ["foo"] ==
             Format.format_field(%{"content" => "foo", "type" => "string", "cardinality" => "*"})

    assert ["foo", "bar"] ==
             Format.format_field(%{
               "content" => "foo|bar",
               "type" => "string",
               "cardinality" => "+"
             })

    assert ["foo", "bar"] ==
             Format.format_field(%{
               "content" => "foo|bar",
               "type" => "string",
               "cardinality" => "*"
             })

    assert ["bar"] ==
             Format.format_field(%{"content" => "bar", "type" => "string", "cardinality" => "+"})

    assert [] ==
             Format.format_field(%{"content" => "", "type" => "string", "cardinality" => "+"})

    assert ["bar|foo"] ==
             Format.format_field(%{
               "content" => "bar|foo",
               "type" => "string",
               "cardinality" => "1"
             })

    assert [1, 23, 45] ==
             Format.format_field(%{
               "content" => "1|23|45|",
               "type" => "integer",
               "cardinality" => "*"
             })

    assert [1, 2.3, 4.5] ==
             Format.format_field(%{
               "content" => "1.0|2.3|4.5|",
               "type" => "float",
               "cardinality" => "*"
             })
  end

  test "format_field of integer and float types" do
    assert 1 == Format.format_field(%{"content" => "1", "type" => "integer"})
    assert 1.5 == Format.format_field(%{"content" => "1.5", "type" => "float"})
  end

  test "flatten_content_fields will list all fields of content" do
    content = [
      %{
        "name" => "group1",
        "fields" => [
          %{"name" => "field11", "label" => "label11", "type" => "string"},
          %{"name" => "field12", "label" => "label12", "cardinality" => "+"}
        ]
      },
      %{
        "name" => "group2",
        "fields" => [
          %{"name" => "field21", "label" => "label21", "widget" => "default"},
          %{"name" => "field22", "label" => "label22", "values" => %{"fixed" => ["a", "b", "c"]}}
        ]
      }
    ]

    flat_content = Format.flatten_content_fields(content)

    expected_flat_content = [
      %{"group" => "group1", "name" => "field11", "label" => "label11", "type" => "string"},
      %{"group" => "group1", "name" => "field12", "label" => "label12", "cardinality" => "+"},
      %{"group" => "group2", "name" => "field21", "label" => "label21", "widget" => "default"},
      %{
        "group" => "group2",
        "name" => "field22",
        "label" => "label22",
        "values" => %{"fixed" => ["a", "b", "c"]}
      }
    ]

    assert flat_content == expected_flat_content
  end

  describe "search_values/2" do
    setup [:create_system, :create_domain]

    test "search_values/2 sets default values and removes redundant fields" do
      content = %{
        "xyzzy" => "spqr",
        "bay" => %{
          "object" => "value",
          "document" => %{
            "data" => %{},
            "nodes" => [
              %{
                "data" => %{},
                "type" => "paragraph",
                "nodes" => [
                  %{
                    "text" => "My Text",
                    "marks" => [
                      %{
                        "data" => %{},
                        "type" => "bold",
                        "object" => "mark"
                      }
                    ],
                    "object" => "text"
                  }
                ],
                "object" => "block"
              }
            ],
            "object" => "document"
          }
        }
      }

      fields = [
        %{
          "name" => "group",
          "fields" => [
            %{"name" => "foo", "default" => "foo"},
            %{"name" => "bar", "cardinality" => "+", "values" => []},
            %{"name" => "baz", "cardinality" => "*", "values" => []},
            %{"name" => "bay", "type" => "enriched_text"}
          ]
        }
      ]

      assert Format.search_values(content, %{content: fields}) == %{
               "foo" => "foo",
               "bar" => [""],
               "baz" => [""],
               "bay" => "My Text"
             }
    end

    test "search_values/2 gets system from cache and formats it", %{system: system} do
      content = %{"system" => %{"id" => system.id}}

      fields = [
        %{
          "name" => "group",
          "fields" => [
            %{"name" => "system", "type" => "system", "cardinality" => 1}
          ]
        }
      ]

      assert %{"system" => [system]} = Format.search_values(content, %{content: fields})

      content = %{"system" => [%{"id" => system.id}]}

      fields = [
        %{
          "name" => "group",
          "fields" => [
            %{"name" => "system", "type" => "system", "cardinality" => "*"}
          ]
        }
      ]

      assert %{"system" => [_system]} = Format.search_values(content, %{content: fields})
    end

    test "search_values/2 gets domain from cache and formats it", %{domain: domain} do
      content = %{"domain" => %{"id" => domain.id}}

      fields = [
        %{
          "name" => "group",
          "fields" => [
            %{"name" => "domain", "type" => "domain", "cardinality" => 1}
          ]
        }
      ]

      assert %{"domain" => [domain]} = Format.search_values(content, %{content: fields})

      content = %{"domain" => [%{"id" => domain.id}]}

      fields = [
        %{
          "name" => "group",
          "fields" => [
            %{"name" => "domain", "type" => "domain", "cardinality" => "*"}
          ]
        }
      ]

      assert %{"domain" => [_domain]} = Format.search_values(content, %{content: fields})
    end

    test "search_values/2 returns nil when no template is provided" do
      content = %{"xyzzy" => "spqr"}
      assert is_nil(Format.search_values(content, nil))
    end

    test "search_values/2 returns nil when no content is provided" do
      fields = [
        %{
          "name" => "group",
          "fields" => [
            %{"name" => "foo", "default" => "foo"},
            %{"name" => "bar", "cardinality" => "+", "values" => []},
            %{"name" => "baz", "cardinality" => "*", "values" => []},
            %{"name" => "bay", "type" => "enriched_text"}
          ]
        }
      ]

      assert is_nil(Format.search_values(nil, fields))
    end

    test "search_values/2 omits values of type image and copy" do
      content = %{
        "xyzzy" => "spqr",
        "foo" => %{
          "object" => "value",
          "document" => %{
            "data" => %{},
            "nodes" => [
              %{
                "data" => %{},
                "type" => "paragraph",
                "nodes" => [
                  %{
                    "text" => "My Text",
                    "marks" => [
                      %{
                        "data" => %{},
                        "type" => "bold",
                        "object" => "mark"
                      }
                    ],
                    "object" => "text"
                  }
                ],
                "object" => "block"
              }
            ],
            "object" => "document"
          }
        },
        "bay" => "photo code...",
        "xyz" => "some json code as tring..."
      }

      fields = [
        %{
          "name" => "group",
          "fields" => [
            %{"name" => "foo", "type" => "enriched_text"},
            %{"name" => "bar", "cardinality" => "+", "values" => []},
            %{"name" => "baz", "cardinality" => "*", "values" => []},
            %{"name" => "bay", "type" => "image"},
            %{"name" => "xyz", "type" => "image"}
          ]
        }
      ]

      assert Format.search_values(content, %{content: fields}) == %{
               "bar" => [""],
               "baz" => [""],
               "foo" => "My Text"
             }
    end
  end

  describe "enrich_content_values/2" do
    setup [:create_system, :create_domain]

    test "enrich_content_values/2 gets cached values on cached type fields", %{
      domain: domain,
      system: system
    } do
      content = %{
        "system" => %{"id" => system.id},
        "domain" => %{"id" => domain.id},
        "foo" => "bar"
      }

      fields = [
        %{
          "name" => "group",
          "fields" => [
            %{"name" => "system", "type" => "system", "cardinality" => 1},
            %{"name" => "domain", "type" => "domain", "cardinality" => "?"},
            %{"name" => "foo", "type" => "string", "cardinality" => "?"}
          ]
        }
      ]

      assert %{"system" => _system, "domain" => _domain, "foo" => "bar"} =
               Format.enrich_content_values(content, %{content: fields})
    end
  end

  defp create_system(_) do
    system = %{id: System.unique_integer([:positive]), external_id: "foo", name: "bar"}
    SystemCache.put(system)

    on_exit(fn ->
      SystemCache.delete(system.id)
      Redix.command(["DEL", "systems:ids_external_ids"])
    end)

    {:ok, system: system}
  end

  defp create_domain(_) do
    domain = %{
      id: System.unique_integer([:positive]),
      external_id: "foo",
      name: "bar",
      updated_at: DateTime.utc_now()
    }

    DomainCache.put(domain)

    on_exit(fn ->
      DomainCache.delete(domain.id)
      Redix.command(["DEL", "domains:ids_to_external_ids"])
    end)

    {:ok, domain: domain}
  end
end
