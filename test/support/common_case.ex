defmodule GitlabApi.CommonCase do
  use ExUnit.CaseTemplate

  import Mox

  using do
    quote do
      import Mox
      import ExUnit.CaptureLog
      import GitlabApi.CommonCase

      setup [:verify_on_exit!]
    end
  end

  def mock_client(status, response, expected_request) do
    expect(GitlabApi.HTTP.ClientMock, :request, fn method, url, body, headers, opts ->
      assert {method, url, body, headers, opts} == expected_request

      {:ok, status, response, [{"Content-Type", "application/json"}]}
    end)
  end

  def client_stub(response) do
    pid = self()

    expect(GitlabApi.HTTP.ClientMock, :request, fn method, uri, body, headers, opts ->
      send(pid, {:request_method, method})
      send(pid, {:request_uri, uri})
      send(pid, {:request_headers, headers})
      send(pid, {:request_body, body})
      send(pid, {:request_opts, opts})

      response
    end)
  end

  def assert_request(method, path, params \\ %{}, opts \\ []) do
    assert_receive {:request_method, ^method}
    assert_receive {:request_uri, uri}
    assert_receive {:request_body, body}
    assert_receive {:request_headers, headers}
    assert_receive {:request_opts, ^opts}

    uri = URI.parse(uri)
    assert uri.scheme == "http"
    assert uri.host == "localhost"
    assert uri.path == path
    assert {"PRIVATE-TOKEN", "secrettoken"} in headers

    if method in [:get, :delete] do
      assert body == ""
      assert URI.decode_query(uri.query || "") == params
    else
      assert uri.query == nil
      assert Jason.decode!(body) == params
      assert {"Content-Type", "application/json"} in headers
    end
  end
end
