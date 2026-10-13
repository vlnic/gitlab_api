defmodule GitlabApi.ContextsTest do
  use ExUnit.Case, async: true

  alias GitlabApi.Contexts

  setup do
    name = "context-#{System.unique_integer([:positive])}"
    on_exit(fn -> Contexts.delete(name) end)
    {:ok, name: name}
  end

  test "stores and replaces a complete connection synchronously", %{name: name} do
    assert :ok =
             Contexts.put(name, host: "https://first.gitlab.test", api_token: "first-token")

    assert {:ok, %{host: "https://first.gitlab.test", api_token: "first-token"}} =
             Contexts.fetch(name)

    assert :ok =
             Contexts.put(name, host: "https://second.gitlab.test", api_token: "second-token")

    assert {:ok, %{host: "https://second.gitlab.test", api_token: "second-token"}} =
             Contexts.fetch(name)
  end

  test "deleting a connection makes it immediately unavailable", %{name: name} do
    assert :ok = Contexts.put(name, host: "https://gitlab.test", api_token: "token")
    assert :ok = Contexts.delete(name)
    assert {:error, :not_found} = Contexts.fetch(name)
    assert :ok = Contexts.delete(name)
  end

  test "unknown names return not_found", %{name: name} do
    assert {:error, :not_found} = Contexts.fetch(name)
  end

  test "invalid configurations leave an existing connection intact", %{name: name} do
    connection = [host: "https://gitlab.test", api_token: "token"]
    assert :ok = Contexts.put(name, connection)

    for invalid <- [
          [],
          [host: "https://gitlab.test"],
          [api_token: "token"],
          [host: nil, api_token: "token"],
          [host: "", api_token: "token"],
          [host: "https://gitlab.test", api_token: nil],
          [host: "https://gitlab.test", api_token: ""],
          [host: "https://gitlab.test", api_token: 123],
          [:invalid],
          %{host: "https://gitlab.test", api_token: "token"},
          nil
        ] do
      assert {:error, :invalid_context} = Contexts.put(name, invalid)
      assert {:ok, %{host: "https://gitlab.test", api_token: "token"}} = Contexts.fetch(name)
    end
  end

  test "invalid names are rejected" do
    for name <- ["", nil, 123, ["name"]] do
      assert {:error, :invalid_context} =
               Contexts.put(name, host: "https://gitlab.test", api_token: "token")
    end
  end

  test "supports existing atom names" do
    name = :test_gitlab_connection
    on_exit(fn -> Contexts.delete(name) end)

    assert :ok = Contexts.put(name, host: "https://gitlab.test", api_token: "token")
    assert {:ok, %{host: "https://gitlab.test", api_token: "token"}} = Contexts.fetch(name)
  end

  test "concurrent readers see complete connections during updates", %{name: name} do
    assert :ok = Contexts.put(name, host: "https://gitlab-0.test", api_token: "token-0")

    writer =
      Task.async(fn ->
        for version <- 1..200 do
          :ok =
            Contexts.put(name,
              host: "https://gitlab-#{version}.test",
              api_token: "token-#{version}"
            )
        end
      end)

    results =
      Task.async_stream(1..16, fn _reader ->
        for _read <- 1..100 do
          assert {:ok, %{host: host, api_token: "token-" <> version}} = Contexts.fetch(name)
          assert host == "https://gitlab-#{version}.test"
        end

        :ok
      end)

    assert Enum.all?(results, &(&1 == {:ok, :ok}))
    Task.await(writer)

    assert {:ok, %{host: "https://gitlab-200.test", api_token: "token-200"}} =
             Contexts.fetch(name)
  end
end
