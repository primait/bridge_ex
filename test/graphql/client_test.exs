defmodule BridgeEx.Graphql.Utils.ClientTest do
  use ExUnit.Case, async: true

  alias BridgeEx.Graphql.Client

  describe "format/1" do
    test "when argument is nil it should return nil" do
      assert Client.format_variables(nil) == nil
    end

    test "when argument is a Date it should return the string representation for that date" do
      {:ok, date} = Date.new(1970, 1, 1)

      date
      |> Client.format_variables()
      |> (&assert(&1 == "1970-01-01")).()
    end

    test "when argument is a DateTime it should return the string representation for that date" do
      {:ok, date} = Date.new(1970, 1, 1)
      {:ok, time} = Time.new(0, 1, 0)
      {:ok, datetime} = DateTime.new(date, time)

      datetime
      |> Client.format_variables()
      |> (&assert(&1 == "1970-01-01 00:01:00Z")).()
    end

    test "when argument is a NaiveDateTime it should return the string representation for that date" do
      {:ok, date} = Date.new(1970, 1, 1)
      {:ok, time} = Time.new(0, 1, 0)
      {:ok, datetime} = NaiveDateTime.new(date, time)

      datetime
      |> Client.format_variables()
      |> (&assert(&1 == "1970-01-01 00:01:00")).()
    end

    test "when argument is a boolean it should return it" do
      true
      |> Client.format_variables()
      |> (&assert(&1 == true)).()
    end

    test "when argument is an atom it should return its uppercased string representation" do
      :bazinga
      |> Client.format_variables()
      |> (&assert(&1 == "BAZINGA")).()
    end

    test "when argument is an integer it should return it" do
      96
      |> Client.format_variables()
      |> (&assert(&1 == 96)).()
    end

    test "when argument is a String it should return it" do
      "With great power comes great responsibility"
      |> Client.format_variables()
      |> (&assert(&1 == "With great power comes great responsibility")).()
    end

    test "when argument is a list it should return the list containig all its values formatted accordingly" do
      {:ok, date} = Date.new(1970, 1, 1)
      {:ok, time} = Time.new(0, 1, 0)
      {:ok, datetime} = DateTime.new(date, time)
      {:ok, naive_datetime} = NaiveDateTime.new(date, time)

      [:mr_strange, 23, "ᚱ", false, date, datetime, naive_datetime]
      |> Client.format_variables()
      |> (&assert(
            &1 == [
              "MR_STRANGE",
              23,
              "ᚱ",
              false,
              "1970-01-01",
              "1970-01-01 00:01:00Z",
              "1970-01-01 00:01:00"
            ]
          )).()
    end

    test "when argument is a map it should return the map containig all its values formatted accordingly" do
      {:ok, birth_date} = Date.new(2001, 5, 25)

      %{
        name: "Peter",
        surname: "Parker",
        is_avenger: true,
        birth_date: birth_date
      }
      |> Client.format_variables()
      |> (&assert(
            &1 == %{
              "name" => "Peter",
              "surname" => "Parker",
              "isAvenger" => true,
              "birthDate" => "2001-05-25"
            }
          )).()
    end
  end
end
