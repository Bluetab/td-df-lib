defmodule TdDfLib.DateRestrictionsTest do
  use ExUnit.Case, async: true

  alias TdDfLib.DateRestrictions

  @fixture Path.expand("../fixtures/date_restrictions.json", __DIR__)

  @now_date ~D[2026-10-15]
  @now_datetime ~N[2026-10-15 20:44:30]

  @range %{"between" => %{"mode" => "static", "start" => "2026-01-01", "end" => "2026-12-31"}}

  describe "resolve/3" do
    setup do
      cases = @fixture |> File.read!() |> Jason.decode!()
      {:ok, cases: cases}
    end

    test "every fixture case resolves to its expected bounds", %{cases: cases} do
      for c <- cases do
        now = resolve_now(c["type"], c["now"])

        assert DateRestrictions.resolve(c["restrictions"], c["type"], now) ==
                 c["expected"],
               """
               case: #{c["id"]}
                 restrictions: #{inspect(c["restrictions"])}
                 now:          #{inspect(c["now"])}
               """
      end
    end
  end

  describe "validate_value/5" do
    test "nil and empty string pass regardless of restrictions" do
      assert :ok == DateRestrictions.validate_value(@range, nil, "date", @now_date)
      assert :ok == DateRestrictions.validate_value(@range, "", "date", @now_date)
      assert :ok == DateRestrictions.validate_value(@range, nil, "datetime", @now_datetime)
      assert :ok == DateRestrictions.validate_value(@range, "", "datetime", @now_datetime)
    end

    test "an empty list passes for a multiple-cardinality field" do
      assert :ok == DateRestrictions.validate_value(@range, [], "date", @now_date)
    end

    test "an empty element inside a list is not a violation" do
      assert :ok == DateRestrictions.validate_value(@range, ["2026-06-01"], "date", @now_date)
      assert :ok == DateRestrictions.validate_value(@range, [nil, ""], "date", @now_date)

      assert {:error, _} =
               DateRestrictions.validate_value(@range, [nil, "2027-01-01"], "date", @now_date)
    end

    test "accepts both bounds inclusive" do
      assert :ok == DateRestrictions.validate_value(@range, "2026-01-01", "date", @now_date)
      assert :ok == DateRestrictions.validate_value(@range, "2026-12-31", "date", @now_date)
      assert :ok == DateRestrictions.validate_value(@range, "2026-06-15", "date", @now_date)
    end

    test "accepts a date-only bound on a datetime field" do
      assert :ok ==
               DateRestrictions.validate_value(
                 %{
                   "between" => %{
                     "mode" => "static",
                     "start" => "2026-06-01",
                     "end" => "2026-06-30"
                   }
                 },
                 "2026-06-15T12:00",
                 "datetime",
                 @now_datetime
               )
    end

    test "rejects below the minimum, naming the limit" do
      assert {:error, {message, opts}} =
               DateRestrictions.validate_value(@range, "2025-12-31", "date", @now_date)

      assert is_binary(message)
      assert Keyword.get(opts, :limit) == "2026-01-01"
    end

    test "rejects above the maximum, naming the limit" do
      assert {:error, {_message, opts}} =
               DateRestrictions.validate_value(@range, "2027-01-01", "date", @now_date)

      assert Keyword.get(opts, :limit) == "2026-12-31"
    end

    test "reports the datetime limit at minute precision" do
      restrictions = %{
        "between" => %{
          "mode" => "static",
          "start" => "2026-06-01",
          "end" => "2026-06-30T10:00:00"
        }
      }

      assert {:error, {_message, opts}} =
               DateRestrictions.validate_value(
                 restrictions,
                 "2026-06-30T10:01",
                 "datetime",
                 @now_datetime
               )

      assert Keyword.get(opts, :limit) == "2026-06-30T10:00"
    end

    test "a minute is the resolution: the very minute of the bound is still valid" do
      restrictions = %{"max_date" => %{"mode" => "static", "value" => "2026-06-30T10:00"}}

      assert :ok ==
               DateRestrictions.validate_value(
                 restrictions,
                 "2026-06-30T10:00",
                 "datetime",
                 @now_datetime
               )

      assert {:error, _} =
               DateRestrictions.validate_value(
                 restrictions,
                 "2026-06-30T10:01",
                 "datetime",
                 @now_datetime
               )
    end

    test "a relative restriction rejects a date before now - N" do
      restrictions = %{"min_date" => %{"mode" => "dynamic", "amount" => -7, "unit" => "days"}}

      assert :ok == DateRestrictions.validate_value(restrictions, "2026-10-08", "date", @now_date)

      assert {:error, {_message, opts}} =
               DateRestrictions.validate_value(restrictions, "2026-10-07", "date", @now_date)

      assert Keyword.get(opts, :limit) == "2026-10-08"
    end

    test "a relative datetime bound keeps the current hour and minute, not midnight" do
      restrictions = %{"max_date" => %{"mode" => "dynamic", "amount" => 1, "unit" => "days"}}

      assert :ok ==
               DateRestrictions.validate_value(
                 restrictions,
                 "2026-10-16T20:44",
                 "datetime",
                 @now_datetime
               )

      assert {:error, _} =
               DateRestrictions.validate_value(
                 restrictions,
                 "2026-10-16T20:45",
                 "datetime",
                 @now_datetime
               )
    end

    test "an unchanged value is not validated, even if it is now out of range" do
      restrictions = %{"max_date" => %{"mode" => "static", "value" => "2026-12-31"}}
      stored = "2030-01-01"

      assert {:error, _} =
               DateRestrictions.validate_value(restrictions, stored, "date", @now_date)

      assert :ok ==
               DateRestrictions.validate_value(restrictions, stored, "date", @now_date,
                 previous_value: stored
               )
    end

    test "a touched value is validated even when it equals a different previous value" do
      restrictions = %{"max_date" => %{"mode" => "static", "value" => "2026-12-31"}}

      assert {:error, _} =
               DateRestrictions.validate_value(restrictions, "2030-01-01", "date", @now_date,
                 previous_value: "2026-06-01"
               )
    end

    test "an unchanged value on a datetime field is also skipped" do
      restrictions = %{"max_date" => %{"mode" => "static", "value" => "2026-12-31T10:00:00"}}
      stored = "2030-01-01T09:00"

      assert :ok ==
               DateRestrictions.validate_value(restrictions, stored, "datetime", @now_datetime,
                 previous_value: stored
               )
    end

    test "accepts a list where every element is in range" do
      assert :ok ==
               DateRestrictions.validate_value(
                 @range,
                 ["2026-03-01", "2026-07-01"],
                 "date",
                 @now_date
               )
    end

    test "rejects the list when one element is out of range, naming the limit" do
      assert {:error, {_message, opts}} =
               DateRestrictions.validate_value(
                 @range,
                 ["2026-03-01", "2027-07-01"],
                 "date",
                 @now_date
               )

      assert Keyword.get(opts, :limit) == "2026-12-31"
    end

    test "no restrictions leaves the value valid" do
      assert :ok == DateRestrictions.validate_value(nil, "2030-01-01", "date", @now_date)
      assert :ok == DateRestrictions.validate_value(%{}, "2030-01-01", "date", @now_date)
    end

    test "a one-sided restriction only constrains that side" do
      min_only = %{"min_date" => %{"mode" => "static", "value" => "2026-01-01"}}

      assert :ok == DateRestrictions.validate_value(min_only, "2030-01-01", "date", @now_date)

      assert {:error, _} =
               DateRestrictions.validate_value(min_only, "2025-01-01", "date", @now_date)
    end

    test "a malformed restriction yields an open bound instead of raising" do
      assert :ok ==
               DateRestrictions.validate_value(
                 %{"min_date" => %{"mode" => "dynamic", "amount" => "x", "unit" => "days"}},
                 "2026-06-01",
                 "date",
                 @now_date
               )
    end

    test "a non-date field type is never constrained" do
      assert :ok == DateRestrictions.validate_value(@range, "2030-01-01", "string", @now_date)
    end

    test "an unparseable value is not reported as out of range" do
      assert :ok == DateRestrictions.validate_value(@range, "not-a-date", "date", @now_date)
    end
  end

  defp resolve_now("date", nil), do: Date.utc_today()
  defp resolve_now("datetime", nil), do: DateTime.to_naive(DateTime.utc_now())
  defp resolve_now("date", %Date{} = d), do: d
  defp resolve_now("datetime", %NaiveDateTime{} = ndt), do: ndt

  defp resolve_now("date", iso) do
    {:ok, date} = Date.from_iso8601(String.slice(iso, 0, 10))
    date
  end

  defp resolve_now("datetime", iso) do
    {:ok, dt, _offset} = DateTime.from_iso8601(iso)
    DateTime.to_naive(dt)
  end
end
