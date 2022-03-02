defmodule BridgeEx.Graphql.LanguageConventions do
  @moduledoc """
  This defines an adapter that supports GraphQL query documents in their
  conventional (in JS) camelCase notation, while allowing the schema to be
  defined using conventional (in Elixir) snake_case notation, and
  tranforming the names as needed for lookups, results, and error messages.

  For example, this document:

  ```
  {
    myUser: createUser(userId: 2) {
      firstName
      lastName
    }
  }
  ```

  Would map to an internal schema that used the following names:

  * `create_user` instead of `createUser`
  * `user_id` instead of `userId`
  * `first_name` instead of `firstName`
  * `last_name` instead of `lastName`

  Likewise, the result of executing this (camelCase) query document against our
  (snake_case) schema would have its names transformed back into camelcase on the
  way out:

  ```
  %{
    data: %{
      "myUser" => %{
        "firstName" => "Joe",
        "lastName" => "Black"
      }
    }
  }
  ```

  Note variables are a client-facing concern (they may be provided as
  parameters), so variable names should match the convention of the query
  document (eg, camelCase).
  """

  use Absinthe.Adapter

  @doc """
  Converts a camelCase to snake_case

  iex> to_internal_name("test", :read)
  "test"

  iex> to_internal_name("testTTT", :read)
  "test_t_t_t"

  iex> to_internal_name("testTest", :read)
  "test_test"

  iex> to_internal_name("testTest1", :read)
  "test_test_1"

  iex> to_internal_name("testTest11", :read)
  "test_test_11"

  iex> to_internal_name("testTest11Pippo", :read)
  "test_test_11_pippo"

  iex> to_internal_name("camelCase23Snake4344", :read)
  "camel_case_23_snake_4344"
  """
  def to_internal_name(nil, _role) do
    nil
  end

  def to_internal_name("__" <> camelized_name, role) do
    "__" <> to_internal_name(camelized_name, role)
  end

  def to_internal_name(camelized_name, :operation) do
    camelized_name
  end

  def to_internal_name(camelized_name, _role) do
    ~r/([A-Z]|\d+)/
    |> Regex.replace(camelized_name, "_\\1")
    |> String.downcase()
  end

  defdelegate to_external_name(underscored_name, role), to: Absinthe.Adapter.LanguageConventions
end
