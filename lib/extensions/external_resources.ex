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
    {resources_opt, opts} = Keyword.pop(opts, :resources)

    if not is_list(resources_opt) do
      raise ArgumentError,
            """
            resources argument in "use #{__MODULE__}" is mandatory and must be a list, got: #{inspect(resources_opt)}
            """
    end

    {includes_opt, opts} = Keyword.pop(opts, :includes, [])

    if not is_list(includes_opt) do
      raise ArgumentError,
            """
            includes argument in "use #{__MODULE__}" must be a list, got: #{inspect(includes_opt)}
            """
    end

    if not Enum.empty?(opts) do
      raise ArgumentError,
            """
            got unexpected argument in "use #{__MODULE__}": #{inspect(opts)}
            """
    end

    if is_nil(__CALLER__.module) do
      raise ArgumentError,
            """
            "use #{__MODULE__}" must be called inside a module
            """
    end

    includes_section = Enum.map_join(includes_opt, "\n", &read_ext_res!(__CALLER__, &1))

    resources =
      Enum.map(resources_opt, fn {name, path} ->
        content = read_ext_res!(__CALLER__, path)

        if includes_section == "" do
          {name, content}
        else
          {name, "#{includes_section}\n#{content}"}
        end
      end)

    quote bind_quoted: [resources: resources, callback: __MODULE__] do
      if not Module.has_attribute?(__MODULE__, :bridge_ex_external_resources) do
        Module.register_attribute(__MODULE__, :bridge_ex_external_resources, accumulate: true)
        Module.put_attribute(__MODULE__, :before_compile, callback)
      end

      Module.put_attribute(__MODULE__, :bridge_ex_external_resources, resources)
    end
  end

  defmacro __before_compile__(%Macro.Env{} = env) do
    resources_list =
      env.module
      |> Module.get_attribute(:bridge_ex_external_resources, [])
      |> List.flatten()

    resources_map =
      Enum.reduce(resources_list, %{}, fn {name, content}, map ->
        if Map.has_key?(map, name) do
          raise ArgumentError, """
          resource names must be unique in "use #{__MODULE__}", got duplicate: #{inspect(name)}
          """
        end

        Map.put(map, name, content)
      end)

    getters =
      for {name, _content} <- resources_map do
        quote do
          @spec unquote(name)() :: String.t()
          def unquote(name)(), do: Map.fetch!(external_resources(), unquote(name))
        end
      end

    quote generated: true do
      @spec external_resources :: %{atom => String.t()}
      defp external_resources, do: unquote(Macro.escape(resources_map))

      unquote_splicing(getters)
    end
  end

  @spec read_ext_res!(Macro.Env.t(), rel_path :: Path.t()) :: binary
  defp read_ext_res!(%Macro.Env{file: file, module: module}, rel_path) do
    path = file |> Path.dirname() |> Path.join(rel_path)
    content = File.read!(path)
    Module.put_attribute(module, :external_resource, path)

    content
  end
end
