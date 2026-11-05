defmodule GitlabApi.APITest do
  use GitlabApi.CommonCase, async: true

  defmodule Params do
    use Construct

    structure do
      field(:name, :string)
    end
  end

  defmodule Client do
    use GitlabApi.API

    alias GitlabApi.APITest.Params
    alias GitlabApi.Types.StringOrInteger

    action :by_map,
      endpoint: {:get, "/api/v4/example"},
      params: %{name: :string}

    action :by_module,
      endpoint: {:post, "/api/v4/example"},
      params: Params

    action :by_primitive,
      endpoint: {:get, "/api/v4/example/:_"},
      params: {:primitive, StringOrInteger}

    action :without_params,
      endpoint: {:get, "/api/v4/example"},
      params_fn: :empty

    action :with_defaults,
      endpoint: {:get, "/api/v4/example"},
      receive_timeout: 1000

    action :transformed,
      endpoint: {:get, "/api/v4/example"},
      params: [name: :string],
      params_fn: fn params -> %{search: params.name} end
  end

  test "accepts parameter definitions as a map" do
    client_stub({:ok, 200, "[]", []})

    assert Client.by_map(%{name: "Flight", ignored: true}) == {:ok, []}
    assert_request(:get, "/api/v4/example", %{"name" => "Flight"})
  end

  test "casts parameters through a Construct module" do
    client_stub({:ok, 201, "{\"id\":42}", []})

    assert Client.by_module(%{name: "Flight"}) == {:ok, %{"id" => 42}}
    assert_request(:post, "/api/v4/example", %{"name" => "Flight"})
  end

  test "casts a custom primitive type and encodes it in the path" do
    client_stub({:ok, 200, "[]", []})

    assert Client.by_primitive("team/flight") == {:ok, []}
    assert_request(:get, "/api/v4/example/team%2Fflight")
  end

  test "rejects invalid custom primitive values before HTTP" do
    assert Client.by_primitive([]) == {:error, {:primitive_type_error, []}}
  end

  test "rejects missing map and module parameters before HTTP" do
    assert Client.by_map() == {:error, %{name: :missing}}
    assert Client.by_module() == {:error, %{name: :missing}}
  end

  test "supports explicitly clearing request parameters" do
    client_stub({:ok, 200, "[]", []})

    assert Client.without_params(%{ignored: "value"}) == {:ok, []}
    assert_request(:get, "/api/v4/example")
  end

  test "passes default client options" do
    client_stub({:ok, 200, "[]", []})

    assert Client.with_defaults() == {:ok, []}
    assert_request(:get, "/api/v4/example", %{}, receive_timeout: 1000)
  end

  test "per-call options override action defaults" do
    client_stub({:ok, 200, "[]", []})

    assert Client.with_defaults(%{}, receive_timeout: 2000) == {:ok, []}
    assert_request(:get, "/api/v4/example", %{}, receive_timeout: 2000)
  end

  test "transforms cast parameters before constructing the request" do
    client_stub({:ok, 200, "[]", []})

    assert Client.transformed(%{name: "Flight"}) == {:ok, []}
    assert_request(:get, "/api/v4/example", %{"search" => "Flight"})
  end

  test "defines a behaviour callback for every action arity" do
    callbacks = Client.Behaviour.behaviour_info(:callbacks)

    for action <- [
          :by_map,
          :by_module,
          :by_primitive,
          :without_params,
          :with_defaults,
          :transformed
        ],
        arity <- 0..2 do
      assert {action, arity} in callbacks
    end
  end

  test "rejects an invalid endpoint when compiling an API module" do
    assert_raise RuntimeError, ~r/method accept \{http_method, path\}/, fn ->
      Code.compile_quoted(
        quote do
          defmodule InvalidEndpoint do
            use GitlabApi.API

            action :request, endpoint: "invalid"
          end
        end
      )
    end
  end
end
