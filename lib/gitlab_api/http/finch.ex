defmodule GitlabApi.HTTP.Finch do
  @behaviour GitlabApi.HTTP

  @req_opts [:pool_timeout, :receive_timeout, :request_timeout, :pool_strategy]
  @pool_opts [:unix_socket, :pool_tag]

  def request(method, uri, body, headers, opts) do
    method
    |> Finch.build(uri, headers, body, Keyword.take(opts, @pool_opts))
    |> Finch.request(GitlabApi.finch_name(), Keyword.take(opts, @req_opts))
    |> parse_response()
  end

  defp parse_response({:ok, %{status: s, body: b, headers: h}}), do: {:ok, s, b, h}
  defp parse_response({:error, %Mint.TransportError{reason: reason}}), do: {:error, reason}
  defp parse_response({:error, %Mint.HTTPError{reason: reason}}), do: {:error, reason}
end
