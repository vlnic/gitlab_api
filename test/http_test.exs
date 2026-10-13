defmodule GitlabApi.HTTPTest do
  use GitlabApi.CommonCase

  describe "failure log redaction" do
    test "omits the configured token and retains useful failure metadata" do
      token = GitlabApi.auth_token()

      expect(GitlabApi.HTTP.ClientMock, :request, fn :get, uri, "", headers, [] ->
        assert uri == "http://localhost/api/v4/version"
        assert headers == [{"PRIVATE-TOKEN", token}]
        {:error, :timeout}
      end)

      log =
        capture_log(fn ->
          assert GitlabApi.Version.version() == {:error, %{reason: :timeout}}
        end)

      refute log =~ token
      refute log =~ "PRIVATE-TOKEN"
      assert log =~ "failed request:"
      assert log =~ "method: :get"
      assert log =~ "uri: \"http://localhost\""
      assert log =~ "status: 0"
      assert log =~ "error: :timeout"
    end

    test "omits token overrides, passwords, nested variables and custom options" do
      token = "override-token-secret"

      params = %{
        password: "user-password-secret",
        variables: [%{key: "CUSTOM_NAME", value: "pipeline-variable-secret"}],
        inputs: %{arbitrary_name: "pipeline-input-secret"}
      }

      opts = [api_token: token, custom_option: "custom-option-secret"]

      expect(GitlabApi.HTTP.ClientMock, :request, fn :post, uri, body, headers, recv_opts ->
        assert uri == "http://localhost/api/v4/example"
        assert body == Jason.encode!(params)
        assert headers == [{"PRIVATE-TOKEN", token}]
        assert recv_opts == opts
        {:error, :closed}
      end)

      log =
        capture_log(fn ->
          assert GitlabApi.HTTP.request(:post, "/api/v4/example", params, opts) ==
                   {:error, %{reason: :closed}}
        end)

      for secret <- [
            token,
            "user-password-secret",
            "pipeline-variable-secret",
            "pipeline-input-secret",
            "custom-option-secret"
          ] do
        refute log =~ secret
      end

      assert log =~ "method: :post"
      assert log =~ "error: :closed"
    end

    test "omits URI credentials, path parameters, queries and fragments" do
      original_host = Application.fetch_env!(:gitlab_api, :host)
      on_exit(fn -> Application.put_env(:gitlab_api, :host, original_host) end)

      Application.put_env(
        :gitlab_api,
        :host,
        "http://uri-user-secret:uri-password-secret@localhost"
      )

      params = %{
        id: "path-secret",
        password: "query-secret#fragment-secret"
      }

      expect(GitlabApi.HTTP.ClientMock, :request, fn :get, uri, "", _headers, [] ->
        assert uri ==
                 "http://uri-user-secret:uri-password-secret@localhost/api/v4/projects/path-secret?password=query-secret#fragment-secret"

        {:error, :timeout}
      end)

      log =
        capture_log(fn ->
          assert GitlabApi.HTTP.request(:get, "/api/v4/projects/:id", params, []) ==
                   {:error, %{reason: :timeout}}
        end)

      for secret <- [
            "uri-user-secret",
            "uri-password-secret",
            "path-secret",
            "query-secret",
            "fragment-secret"
          ] do
        refute log =~ secret
      end

      assert log =~ "uri: \"http://localhost\""
    end

    test "redacts arbitrary transport error data without changing the returned error" do
      error =
        {:transport_error, %{message: "error-message-secret", request: "request-copy-secret"}}

      client_stub({:error, error})

      log =
        capture_log(fn ->
          assert GitlabApi.Version.version() == {:error, %{reason: error}}
        end)

      refute log =~ "error-message-secret"
      refute log =~ "request-copy-secret"
      assert log =~ "error: \"[REDACTED]\""
    end

    test "omits response headers and bodies when an unexpected status is logged" do
      client_stub({:ok, 302, "response-body-secret", [{"set-cookie", "response-cookie-secret"}]})

      log =
        capture_log(fn ->
          assert GitlabApi.Version.version() == {:error, %{reason: nil}}
        end)

      refute log =~ "response-body-secret"
      refute log =~ "response-cookie-secret"
      assert log =~ "status: 302"
    end
  end
end
