defmodule GitlabApi.Contexts do
  @moduledoc """
  Stores named GitLab connections in memory on the current node.

  Writes are synchronous and reads access ETS directly. Pass a stored name in
  an endpoint's options to select its connection:

      GitlabApi.Contexts.put("work",
        host: "https://gitlab.company.com",
        api_token: token
      )

      GitlabApi.Projects.get(123, context: "work")

  Omitting `:context` uses the application's configured host and token.
  A request's explicit `:api_token` overrides the stored token.

  Connections are lost when this process or the application restarts. Names
  can be strings or existing atoms; strings are suitable for dynamic names.
  """

  use GenServer

  @type name :: binary() | atom()
  @type context :: %{host: binary(), api_token: binary()}

  @doc false
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Creates or replaces a connection, returning after it is stored.

  Both `:host` and `:api_token` must be nonempty strings. Invalid input returns
  `{:error, :invalid_context}` without changing an existing connection.
  """
  @spec put(name(), Keyword.t()) :: :ok | {:error, :invalid_context}
  def put(name, opts) do
    with true <- valid_name?(name),
         true <- Keyword.keyword?(opts),
         {:ok, host} when is_binary(host) and byte_size(host) > 0 <- Keyword.fetch(opts, :host),
         {:ok, token} when is_binary(token) and byte_size(token) > 0 <-
           Keyword.fetch(opts, :api_token) do
      GenServer.call(__MODULE__, {:put, name, %{host: host, api_token: token}})
    else
      _ -> {:error, :invalid_context}
    end
  end

  @doc """
  Fetches a connection directly from ETS.

  Returns `{:error, :not_found}` for an unknown name, or
  `{:error, :unavailable}` while the store is not running.
  """
  @spec fetch(name()) :: {:ok, context()} | {:error, :not_found | :unavailable}
  def fetch(name) do
    case :ets.lookup(__MODULE__, name) do
      [{^name, context}] -> {:ok, context}
      [] -> {:error, :not_found}
    end
  rescue
    ArgumentError -> {:error, :unavailable}
  end

  @doc "Deletes a connection synchronously. Deleting an unknown name also returns `:ok`."
  @spec delete(name()) :: :ok
  def delete(name) do
    GenServer.call(__MODULE__, {:delete, name})
  end

  @impl true
  def init(:ok) do
    table = :ets.new(__MODULE__, [:named_table, :set, :protected, read_concurrency: true])
    {:ok, table}
  end

  @impl true
  def handle_call({:put, name, context}, _from, table) do
    :ets.insert(table, {name, context})
    {:reply, :ok, table}
  end

  def handle_call({:delete, name}, _from, table) do
    :ets.delete(table, name)
    {:reply, :ok, table}
  end

  defp valid_name?(name) when is_binary(name), do: byte_size(name) > 0
  defp valid_name?(name) when is_atom(name), do: not is_nil(name)
  defp valid_name?(_name), do: false
end
