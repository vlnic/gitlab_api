defmodule GitlabApi.HTTPTest do
  use GitlabApi.CommonCase

  alias GitlabApi.HTTP

  @responses [
    {200, "{\"id\":123}", {:ok, %{"id" => 123}}},
    {201, "[1,2]", {:ok, [1, 2]}},
    {200, "plain text", {:ok, "plain text"}},
    {204, "", {:ok, ""}},
    {400, "{\"message\":\"Invalid request\"}",
     {:error, %{reason: %{"message" => "Invalid request"}}}},
    {401, "Unauthorized", {:error, %{reason: "Unauthorized"}}},
    {404, "{\"message\":\"Not found\"}", {:error, %{reason: %{"message" => "Not found"}}}},
    {429, "Too many requests", {:error, %{reason: "Too many requests"}}},
    {500, "Internal error", {:error, %{reason: "service_unavailable"}}},
    {503, "Unavailable", {:error, %{reason: "service_unavailable"}}}
  ]

  for {status, body, expected} <- @responses do
    test "handles HTTP #{status} with body #{inspect(body)}" do
      client_stub({:ok, unquote(status), unquote(body), []})

      assert HTTP.request(:get, "/api/v4/user", %{}, []) ==
               unquote(Macro.escape(expected))

      assert_request(:get, "/api/v4/user")
    end
  end

  test "overrides the token and forwards client options" do
    mock_client(200, "[]", {
      :get,
      "http://localhost/api/v4/users",
      "",
      [{"PRIVATE-TOKEN", "custom-token"}],
      [receive_timeout: 1234, pool_timeout: 5678]
    })

    opts = [api_token: "custom-token", receive_timeout: 1234, pool_timeout: 5678]
    assert GitlabApi.Users.list(%{}, opts) == {:ok, []}
  end

  test "encodes query values without allowing them to add parameters or fragments" do
    client_stub({:ok, 200, "[]", []})
    search = "тест &scope=users#fragment + ? /"

    assert GitlabApi.GlobalSearch.request(%{search: search, scope: "projects"}) == {:ok, []}
    assert_request(:get, "/api/v4/search", %{"search" => search, "scope" => "projects"})
  end

  test "encodes a path parameter as one segment" do
    client_stub({:ok, 200, "[]", []})

    params = %{
      group: "team/subgroup",
      search: "flight",
      scope: "projects"
    }

    assert GitlabApi.GroupSearch.request(params) == {:ok, []}

    assert_request(:get, "/api/v4/groups/team%2Fsubgroup/search", %{
      "search" => "flight",
      "scope" => "projects"
    })
  end

  test "keeps false and zero parameters while omitting nil values" do
    client_stub({:ok, 200, "[]", []})

    assert HTTP.request(:get, "/api/v4/users", %{active: false, page: 0, search: nil}, []) ==
             {:ok, []}

    assert_request(:get, "/api/v4/users", %{"active" => "false", "page" => "0"})
  end

  test "normalizes struct parameters" do
    client_stub({:ok, 200, "[]", []})

    assert HTTP.request(:post, "/api/v4/example", %URI{path: "example"}, []) == {:ok, []}
    assert_request(:post, "/api/v4/example", %{"path" => "example"})
  end

  test "returns transport errors without logging credentials or request data" do
    secret = "private-request-secret"
    client_stub({:error, :timeout})

    params = %{
      username: "user.test",
      name: "User Test",
      email: "private@example.com",
      password: secret
    }

    log =
      capture_log(fn ->
        assert GitlabApi.Users.create(params, api_token: secret) == {:error, %{reason: :timeout}}
      end)

    assert log =~ "[error]"
    assert log =~ "HTTP request"
    assert log =~ "transport_error"
    refute log =~ secret
    refute log =~ "private@example.com"
    refute log =~ "secrettoken"
  end

  test "does not log sensitive data embedded in the transport error" do
    reason = {:invalid_response, "sensitive-response"}
    client_stub({:error, reason})

    log =
      capture_log(fn ->
        assert GitlabApi.Version.version() == {:error, %{reason: reason}}
      end)

    assert log =~ "transport_error"
    refute log =~ "sensitive-response"
  end
end
