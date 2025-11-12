defmodule TdDfLib.Format.DateTimeTest do
  use ExUnit.Case

  alias TdDfLib.Format.DateTime, as: FormatDateTime

  describe "convert_to_iso8601/2" do
    test "converts - string date and datetime to iso8601 string" do
      value = "2025-12-31"
      assert FormatDateTime.convert_to_iso8601(value, "date") == {:ok, "2025-12-31"}

      value = "31-12-2025"
      assert FormatDateTime.convert_to_iso8601(value, "date") == {:ok, "2025-12-31"}

      value = "31-12-2025 22:55:30"
      assert FormatDateTime.convert_to_iso8601(value, "datetime") == {:ok, "2025-12-31T22:55:30"}

      value = "2025-12-31 22:55:30"

      assert FormatDateTime.convert_to_iso8601(value, "datetime") ==
               {:ok, "2025-12-31T22:55:30"}
    end

    test "converts / string date and datetime to iso8601 string" do
      value = "2025/12/31"
      assert FormatDateTime.convert_to_iso8601(value, "date") == {:ok, "2025-12-31"}

      value = "31/12/2025"
      assert FormatDateTime.convert_to_iso8601(value, "date") == {:ok, "2025-12-31"}

      value = "31/12/2025 22:55:30"
      assert FormatDateTime.convert_to_iso8601(value, "datetime") == {:ok, "2025-12-31T22:55:30"}

      value = "31/12/2025 22:55:30"
      assert FormatDateTime.convert_to_iso8601(value, "datetime") == {:ok, "2025-12-31T22:55:30"}
    end

    test "converts DateTime structs to iso8601 string" do
      value = ~N[2025-12-31 22:55:30]

      assert FormatDateTime.convert_to_iso8601(value, "datetime") ==
               {:ok, "2025-12-31T22:55:30"}
    end

    test "converts integer date and datetime to iso8601 string" do
      value = 45_995
      assert FormatDateTime.convert_to_iso8601(value, "date") == {:ok, "2025-12-31"}

      value = "45995"
      assert FormatDateTime.convert_to_iso8601(value, "date") == {:ok, "2025-12-31"}

      value = 45_995
      assert FormatDateTime.convert_to_iso8601(value, "datetime") == {:ok, "2025-12-31T00:00:00"}
      value = "45995"
      assert FormatDateTime.convert_to_iso8601(value, "datetime") == {:ok, "2025-12-31T00:00:00"}
    end

    test "converts float date and datetime to iso8601 string" do
      value = 45_995.9552083333
      assert FormatDateTime.convert_to_iso8601(value, "date") == {:ok, "2025-12-31"}
      value = "45995.9552083333"
      assert FormatDateTime.convert_to_iso8601(value, "date") == {:ok, "2025-12-31"}

      value = 45_995.9552083333
      assert FormatDateTime.convert_to_iso8601(value, "datetime") == {:ok, "2025-12-31T22:55:30"}
      value = "45995.9552083333"
      assert FormatDateTime.convert_to_iso8601(value, "datetime") == {:ok, "2025-12-31T22:55:30"}
    end

    test "returns error for invalid date" do
      assert FormatDateTime.convert_to_iso8601("foo", "date") == :error
    end

    test "returns error for invalid datetime" do
      assert FormatDateTime.convert_to_iso8601("foo", "datetime") == :error
    end

    test "returns error for impossible date and datetime" do
      assert FormatDateTime.convert_to_iso8601("2024-12-40", "date") == :error
      assert FormatDateTime.convert_to_iso8601("2024-12-00", "date") == :error
      assert FormatDateTime.convert_to_iso8601("2024-13-01", "date") == :error
      assert FormatDateTime.convert_to_iso8601("2024-00-01", "date") == :error
      assert FormatDateTime.convert_to_iso8601("40-12-2024", "date") == :error
      assert FormatDateTime.convert_to_iso8601("00-12-2024", "date") == :error
      assert FormatDateTime.convert_to_iso8601("01-13-2024", "date") == :error
      assert FormatDateTime.convert_to_iso8601("01-00-2024", "date") == :error
      assert FormatDateTime.convert_to_iso8601("29-02-2024", "date") == :error

      assert FormatDateTime.convert_to_iso8601("2024-12-40 22:55:30", "datetime") == :error
      assert FormatDateTime.convert_to_iso8601("2024-12-00 22:55:30", "datetime") == :error
      assert FormatDateTime.convert_to_iso8601("2024-13-01 22:55:30", "datetime") == :error
      assert FormatDateTime.convert_to_iso8601("2024-00-01 22:55:30", "datetime") == :error
      assert FormatDateTime.convert_to_iso8601("40-12-2024 22:55:30", "datetime") == :error
      assert FormatDateTime.convert_to_iso8601("00-12-2024 22:55:30", "datetime") == :error
      assert FormatDateTime.convert_to_iso8601("01-13-2024 22:55:30", "datetime") == :error
      assert FormatDateTime.convert_to_iso8601("01-00-2024 22:55:30", "datetime") == :error
      assert FormatDateTime.convert_to_iso8601("29-02-2024 22:55:30", "datetime") == :error

      assert FormatDateTime.convert_to_iso8601("2024-12-31 25:65:30", "datetime") == :error
      assert FormatDateTime.convert_to_iso8601("2024-12-31 24:60:30", "datetime") == :error
      assert FormatDateTime.convert_to_iso8601("2024-12-31 23:60:30", "datetime") == :error
      assert FormatDateTime.convert_to_iso8601("2024-12-31 23:59:60", "datetime") == :error
    end

    test "returns empty string for empty strings date and datetime" do
      assert FormatDateTime.convert_to_iso8601("", "date") == {:ok, ""}
      assert FormatDateTime.convert_to_iso8601("", "datetime") == {:ok, ""}
    end

    test "returns nil for nil date and datetime" do
      assert FormatDateTime.convert_to_iso8601(nil, "date") == {:ok, nil}
      assert FormatDateTime.convert_to_iso8601(nil, "datetime") == {:ok, nil}
    end

    test "returns value for non date and datetime types" do
      assert FormatDateTime.convert_to_iso8601("foo", "other_type") == {:ok, "foo"}
      assert FormatDateTime.convert_to_iso8601(123, "other_type") == {:ok, 123}
    end
  end
end
