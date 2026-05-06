defmodule BridgeEx.Extensions.ExternalResources do
  @moduledoc """
  Preload a set of resources marking them as "external" and provide the related getter functions.

  ## Options

    * `resources` (required): enumerable of resource names (atoms) and their paths (strings).
      Each path is assumed to be relative to the module directory.
    * `includes` (optional): enumerable of paths (strings) to files that should be prepended to every resource.
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
    @spec my_mutation() :: String.t()
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

  defmacro __using__(opts) do
    {resources, opts} = Keyword.pop(opts, :resources)

    if not is_list(resources) do
      raise ArgumentError,
            """
            resources argument in "use #{__MODULE__}" is mandatory and must be a list, got: #{inspect(opts)}
            """
    end

    {includes, opts} = Keyword.pop(opts, :includes, [])

    if not Enum.empty?(opts) do
      raise ArgumentError,
            """
            got unexpected argument in "use #{__MODULE__}": #{inspect(opts)}
            """
    end

    dir = Path.dirname(__CALLER__.file)

    included_contents =
      for path <- includes, into: "" do
        content = dir |> Path.join(path) |> File.read!()

        "#{content}\n"
      end

    resources_contents =
      for {name, path} <- resources, into: %{} do
        content = dir |> Path.join(path) |> File.read!()

        {name, included_contents <> content}
      end

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
      defp external_resources, do: unquote(Macro.escape(resources_contents))
    end
  end
end
