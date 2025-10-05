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

  def mock_client(status, response, {method, _url, body, headers, opts}) do
    expect(GitlabApi.HTTP.ClientMock, :request, fn(recv_method, _recv_url, recv_body, recv_headers, recv_opts) ->
      assert method == recv_method
      assert headers == recv_headers
      assert body == recv_body
      assert opts == recv_opts

      {:ok, %{status_code: status, body: response, headers: [{"Content-Type", "application/json"}]}}
    end)
  end

  def client_stub(response) do
    pid = self()

    Mox.stub(GitlabApi.HTTP.ClientMock, :request, fn(method, uri, body, headers, opts) ->
      send pid, {:request_method, method}
      send pid, {:request_uri, uri}
      send pid, {:request_headers, headers}
      send pid, {:request_body, body}
      send pid, {:request_opts, opts}

      response
    end)
  end
end
