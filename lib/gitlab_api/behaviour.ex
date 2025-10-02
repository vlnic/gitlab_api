defmodule GitlabApi.Behaviour do
  defmacro __using__(_opts \\ []) do
    quote do
      @after_compile {GitlabApi.API, :__after_compile__}

      Module.register_attribute __MODULE__, :methods, accumulate: true

      def __methods__, do: Module.get_attribute(__MODULE__, :methods)
    end
  end

  def define(module, name) do
    Module.put_attribute(module, :methods, name)
  end

  def define_module(env) do
    module = Module.concat(env.module, Behaviour)
    methods = env.module.__methods__()

    contents = Enum.map(methods, &define_callbacks/1)

    Module.create(module, contents, env)
  end

  defp define_callbacks(method) do
    quote do
      @callback unquote(method)()
                :: :ok | {:ok, term} | {:error, term}

      @callback unquote(method)(params :: map | Keyword.t)
                :: :ok | {:ok, term} | {:error, term}

      @callback unquote(method)(params :: map | Keyword.t, opts :: Keyword.t)
                :: :ok | {:ok, term} | {:error, term}
    end
  end
end
