defmodule TdDfLib.ValidationDateRestrictionsTest do
  use ExUnit.Case, async: true

  alias TdDfLib.Validation

  @now_date ~D[2026-10-15]

  defp schema do
    [
      %{
        "name" => "fecha",
        "label" => "fecha",
        "type" => "date",
        "cardinality" => "?",
        "restrictions" => %{
          "between" => %{"mode" => "static", "start" => "2026-01-01", "end" => "2026-12-31"}
        }
      }
    ]
  end

  defp content(date) do
    %{"fecha" => %{"value" => date, "origin" => "user"}}
  end

  defp errors(date, opts \\ []) do
    schema = schema()

    case Validation.validate_content(
           content(date),
           schema,
           Keyword.put_new(opts, :now, @now_date)
         ) do
      :ok ->
        %{}

      {:error, %{errors: errors}} ->
        Map.new(errors, fn {field, {_msg, _opts}} -> {field, true} end)
    end
  end

  defp error(date, opts \\ []) do
    schema = schema()

    {:error, %{errors: [{:fecha, error}]}} =
      Validation.validate_content(content(date), schema, Keyword.put_new(opts, :now, @now_date))

    error
  end

  describe "a date field with restrictions" do
    test "accepts a value inside the range" do
      assert errors("2026-06-15") == %{}
    end

    test "rejects a value before the range, naming the resolved limit" do
      assert {message, opts} = error("2025-06-15")
      assert message == "errors.date_restrictions.out_of_range"
      assert Keyword.get(opts, :limit) == "2026-01-01"
      assert Keyword.get(opts, :fixed_name) == true
    end

    test "rejects a value after the range" do
      assert {_message, opts} = error("2027-06-15")
      assert Keyword.get(opts, :limit) == "2026-12-31"
    end

    test "the error is attached to the offending field" do
      assert %{fecha: true} = errors("2027-06-15")
    end

    test "accepts an empty value: these records are fillable in part" do
      assert errors("") == %{}
      assert errors(nil) == %{}
    end
  end

  describe "only validate what was touched" do
    test "an unchanged out-of-range value does not block the save" do
      previous = %{"fecha" => %{"value" => "2020-01-01", "origin" => "user"}}

      assert errors("2020-01-01", previous_content: previous) == %{}
    end

    test "the same value is rejected once it has actually changed" do
      previous = %{"fecha" => %{"value" => "2026-06-01", "origin" => "user"}}

      assert %{fecha: true} = errors("2020-01-01", previous_content: previous)
    end

    test "without previous_content everything is validated" do
      assert %{fecha: true} = errors("2020-01-01")
    end
  end

  describe "fields that are not dates are untouched" do
    test "a string field with no restrictions behaves as before" do
      schema = [%{"name" => "s", "label" => "s", "type" => "string", "cardinality" => "?"}]

      assert :ok ==
               Validation.validate_content(
                 %{"s" => %{"value" => "cualquier cosa", "origin" => "user"}},
                 schema
               )
    end

    test "a date field with no restrictions key accepts anything" do
      schema = [%{"name" => "fecha", "label" => "fecha", "type" => "date", "cardinality" => "?"}]

      assert :ok ==
               Validation.validate_content(
                 %{"fecha" => %{"value" => "2020-01-01", "origin" => "user"}},
                 schema
               )
    end

    test "a date field with empty restrictions accepts anything" do
      schema = [
        %{
          "name" => "fecha",
          "label" => "fecha",
          "type" => "date",
          "cardinality" => "?",
          "restrictions" => %{}
        }
      ]

      assert :ok ==
               Validation.validate_content(
                 %{"fecha" => %{"value" => "2020-01-01", "origin" => "user"}},
                 schema
               )
    end
  end

  describe "required validation still applies" do
    test "a required date field with no value is still flagged blank" do
      schema = [
        %{
          "name" => "fecha",
          "label" => "fecha",
          "type" => "date",
          "cardinality" => "1",
          "restrictions" => %{"max_date" => %{"mode" => "static", "value" => "2026-12-31"}}
        }
      ]

      assert {:error, %{errors: errors}} =
               Validation.validate_content(
                 %{"fecha" => %{"value" => "", "origin" => "user"}},
                 schema
               )

      assert [fecha: {"can't be blank", _}] = errors
    end
  end
end
