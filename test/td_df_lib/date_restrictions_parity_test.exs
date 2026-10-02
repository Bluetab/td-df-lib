defmodule TdDfLib.DateRestrictionsParityTest do
  use ExUnit.Case, async: true

  @fixture Path.expand("../fixtures/date_restrictions.json", __DIR__)

  setup_all do
    cases = @fixture |> File.read!() |> Jason.decode!()
    {:ok, cases: cases}
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

  test "the fixture is well formed", %{cases: cases} do
    assert is_list(cases)
    assert length(cases) > 0

    ids = Enum.map(cases, & &1["id"])
    assert length(ids) == length(Enum.uniq(ids)), "fixture ids must be unique"

    for c <- cases do
      assert is_binary(c["id"]), "every case needs an id"
      assert c["type"] in ["date", "datetime"], "unknown type #{inspect(c["type"])} in #{c["id"]}"
      assert is_map(c["restrictions"]), "#{c["id"]}: restrictions must be an object"
      assert is_binary(c["now"]), "#{c["id"]}: now must be explicit, never implicit"
      assert is_map(c["expected"]), "#{c["id"]}: expected must be an object"
      assert Map.has_key?(c["expected"], "min")
      assert Map.has_key?(c["expected"], "max")
    end
  end

  test "`between` carries mode on the parent only, never on each side", %{cases: cases} do
    for %{"restrictions" => %{"between" => between}} <- cases, is_map(between) do
      refute Map.has_key?(between["from"] || %{}, "mode"),
             "`between.from` must not carry mode; it lives on `between`"

      refute Map.has_key?(between["to"] || %{}, "mode"),
             "`between.to` must not carry mode; it lives on `between`"
    end
  end

  describe "resolve/3 against the shared fixture" do
    test "every case resolves to its expected bounds", %{cases: cases} do
      for c <- cases do
        now = resolve_now(c["type"], c["now"])

        assert TdDfLib.DateRestrictions.resolve(c["restrictions"], c["type"], now) ==
                 c["expected"],
               """
               case: #{c["id"]}
                 restrictions: #{inspect(c["restrictions"])}
                 now:          #{inspect(c["now"])}
               """
      end
    end
  end
end
