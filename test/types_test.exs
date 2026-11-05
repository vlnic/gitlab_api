defmodule GitlabApi.TypesTest do
  use ExUnit.Case, async: true

  alias GitlabApi.Types.ISODate
  alias GitlabApi.Types.ISODateTime
  alias GitlabApi.Types.StringOrInteger

  describe "ISODate.cast/1" do
    test "serializes dates and accepts ISO strings" do
      assert ISODate.cast(~D[2026-11-06]) == {:ok, "2026-11-06"}
      assert ISODate.cast("2026-11-06") == {:ok, "2026-11-06"}
    end

    test "rejects invalid dates and unsupported types" do
      for value <- ["2026-02-30", "invalid", nil, 123, %{}] do
        assert ISODate.cast(value) == :error
      end
    end
  end

  describe "ISODateTime.cast/1" do
    test "serializes UTC and naive datetimes" do
      assert ISODateTime.cast(~U[2026-11-06 12:30:00Z]) == {:ok, "2026-11-06T12:30:00Z"}
      assert ISODateTime.cast(~N[2026-11-06 12:30:00]) == {:ok, "2026-11-06T12:30:00"}
    end

    test "returns the Construct success tuple for ISO strings and preserves offsets" do
      for value <- ["2026-11-06T12:30:00Z", "2026-11-06T12:30:00.123+03:00"] do
        assert ISODateTime.cast(value) == {:ok, value}
      end
    end

    test "rejects invalid datetime strings and unsupported types" do
      for value <- ["invalid", "2026-02-30T12:30:00Z", "2026-11-06", nil, 123, %{}] do
        assert ISODateTime.cast(value) == :error
      end
    end
  end

  describe "StringOrInteger.cast/1" do
    test "accepts strings and integers without converting them" do
      for value <- [123, "123", "team/flight"] do
        assert StringOrInteger.cast(value) == {:ok, value}
      end
    end

    test "rejects unsupported types" do
      for value <- [nil, false, 1.5, [], %{}] do
        assert StringOrInteger.cast(value) == :error
      end
    end
  end
end
