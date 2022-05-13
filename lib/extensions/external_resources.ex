defmodule BridgeEx.Extensions.ExternalResources do
  @moduledoc """
  Preload a set of resources marking them as "external" and provide the related getter functions.

  ## Options

    * `resources` (required): enumerable of resource names (atoms) and their paths (strings).
      Each path is assumed to be relative to the module directory.

  ## Examples

  ```elixir
  defmodule MyBridge do
    use BridgeEx.Extensions.ExternalResources,
      resources: [
        my_query: "queries/query.graphql",
        my_mutation: "mutations/mutation.graphql"
      ]

    # it generates the following code:

    @external_resource "\#{__DIR__}/queries/query.graphql"
    @external_resource "\#{__DIR__}/mutations/mutation.graphql"

    @spec my_query() :: String.t()
    def my_query, do: Map.fetch!(external_resources(), :my_query)
    def my_mutation, do: Map.fetch!(external_resources(), :my_mutation)

    defp external_resources do
      %{
        my_query: "contents of query.graphql",
        my_mutation: "contents of mutation.graphql"
      }
    end
  end
  ```
  """

  defmacro __using__(resources: resources) do
    dir = Path.dirname(__CALLER__.file)
    resources = for {name, path} <- resources, do: {name, Path.join(dir, path)}
    contents = for {name, path} <- resources, into: %{}, do: {name, File.read!(path)}

    getters =
      for {name, _path} <- resources do
        quote do
          @spec unquote(name)() :: String.t()
          def unquote(name)(), do: Map.fetch!(external_resources(), unquote(name))
        end
      end

    external_resource_attributes =
      for {_name, path} <- resources do
        quote do: @external_resource(unquote(path))
      end

    quote generated: true do
      unquote_splicing(external_resource_attributes)
      unquote_splicing(getters)
      defp external_resources, do: unquote(Macro.escape(contents))
    end
  end
end
