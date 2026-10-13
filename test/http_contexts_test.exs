defmodule GitlabApi.HTTPContextsTest do
  use GitlabApi.CommonCase

  alias GitlabApi.Contexts

  setup do
    name = "http-context-#{System.unique_integer([:positive])}"
    on_exit(fn -> Contexts.delete(name) end)
    {:ok, name: name}
  end

  test "endpoint options select the stored host and token", %{name: name} do
    :ok = Contexts.put(name, host: "https://work.gitlab.test", api_token: "work-token")

    expect(GitlabApi.HTTP.ClientMock, :request, fn :get, uri, "", headers, opts ->
      assert uri == "https://work.gitlab.test/api/v4/projects/123"
      assert headers == [{"PRIVATE-TOKEN", "work-token"}]
      assert opts == []
      {:ok, 200, ~s({"id":123}), []}
    end)

    assert {:ok, %{"id" => 123}} = GitlabApi.Projects.get(123, context: name)
  end

  test "requests without a context use application configuration" do
    expect(GitlabApi.HTTP.ClientMock, :request, fn :get, uri, "", headers, [] ->
      assert uri == "#{GitlabApi.host()}/api/v4/version"
      assert headers == [{"PRIVATE-TOKEN", GitlabApi.auth_token()}]
      {:ok, 200, "{}", []}
    end)

    assert {:ok, %{}} = GitlabApi.Version.version()
  end

  test "an explicit token overrides the stored token and transport options are preserved", %{
    name: name
  } do
    :ok = Contexts.put(name, host: "https://work.gitlab.test", api_token: "work-token")

    expect(GitlabApi.HTTP.ClientMock, :request, fn :get, uri, "", headers, opts ->
      assert uri == "https://work.gitlab.test/api/v4/projects/123"
      assert headers == [{"PRIVATE-TOKEN", "override-token"}]
      assert opts == [api_token: "override-token", custom_option: "value"]
      {:ok, 200, "{}", []}
    end)

    assert {:ok, %{}} =
             GitlabApi.Projects.get(123,
               context: name,
               api_token: "override-token",
               custom_option: "value"
             )
  end

  test "unknown contexts return an error without contacting the transport", %{name: name} do
    assert {:error, %{reason: {:context_not_found, ^name}}} =
             GitlabApi.Projects.get(123, context: name, api_token: "override-token")
  end

  test "an explicitly supplied nil context does not select application configuration" do
    assert {:error, %{reason: {:context_not_found, nil}}} =
             GitlabApi.Projects.get(123, context: nil)
  end

  test "non-GET requests use the selected connection and retain their body", %{name: name} do
    :ok = Contexts.put(name, host: "https://work.gitlab.test", api_token: "work-token")

    expect(GitlabApi.HTTP.ClientMock, :request, fn :post, uri, body, headers, [] ->
      assert uri == "https://work.gitlab.test/api/v4/example"
      assert Jason.decode!(body) == %{"name" => "example"}
      assert headers == [{"PRIVATE-TOKEN", "work-token"}]
      {:ok, 201, "{}", []}
    end)

    assert {:ok, %{}} =
             GitlabApi.HTTP.request(:post, "/api/v4/example", %{name: "example"}, context: name)
  end

  test "updates affect subsequent requests", %{name: name} do
    for version <- 1..2 do
      host = "https://gitlab-#{version}.test"
      token = "token-#{version}"
      :ok = Contexts.put(name, host: host, api_token: token)

      expect(GitlabApi.HTTP.ClientMock, :request, fn :get, uri, "", headers, [] ->
        assert uri == "#{host}/api/v4/projects/123"
        assert headers == [{"PRIVATE-TOKEN", token}]
        {:ok, 200, "{}", []}
      end)

      assert {:ok, %{}} = GitlabApi.Projects.get(123, context: name)
    end
  end

  test "concurrent callers select connections independently", %{name: prefix} do
    connections =
      for index <- 1..8 do
        name = "#{prefix}-#{index}"
        host = "https://gitlab-#{index}.test"
        token = "token-#{index}"
        :ok = Contexts.put(name, host: host, api_token: token)
        on_exit(fn -> Contexts.delete(name) end)
        {name, "#{host}/api/v4/projects/123", token}
      end

    tokens_by_uri = Map.new(connections, fn {_name, uri, token} -> {uri, token} end)

    expect(GitlabApi.HTTP.ClientMock, :request, length(connections), fn :get,
                                                                        uri,
                                                                        "",
                                                                        headers,
                                                                        [] ->
      assert headers == [{"PRIVATE-TOKEN", Map.fetch!(tokens_by_uri, uri)}]
      {:ok, 200, "{}", []}
    end)

    tasks =
      for {name, _uri, _token} <- connections do
        task =
          Task.async(fn ->
            receive do
              :request -> GitlabApi.Projects.get(123, context: name)
            end
          end)

        allow(GitlabApi.HTTP.ClientMock, self(), task.pid)
        task
      end

    for task <- tasks, do: send(task.pid, :request)
    for task <- tasks, do: assert({:ok, %{}} = Task.await(task))
  end

  test "context tokens are omitted from failure logs", %{name: name} do
    token = "stored-token-secret"
    :ok = Contexts.put(name, host: "https://work.gitlab.test", api_token: token)
    client_stub({:error, :timeout})

    log =
      capture_log(fn ->
        assert {:error, %{reason: :timeout}} =
                 GitlabApi.Projects.get(123, context: name)
      end)

    refute log =~ token
    refute log =~ "PRIVATE-TOKEN"
    assert log =~ "uri: \"https://work.gitlab.test\""
  end

  test "store downtime returns an error and restarting the store clears connections", %{
    name: name
  } do
    :ok = Contexts.put(name, host: "https://work.gitlab.test", api_token: "work-token")
    :ok = Supervisor.terminate_child(GitlabApi.Supervisor, Contexts)

    try do
      assert {:error, :unavailable} = Contexts.fetch(name)

      assert {:error, %{reason: :contexts_unavailable}} =
               GitlabApi.Projects.get(123, context: name)
    after
      {:ok, _pid} = Supervisor.restart_child(GitlabApi.Supervisor, Contexts)
    end

    assert {:error, :not_found} = Contexts.fetch(name)
  end
end
