defmodule GitlabApi.HTTP do
  @type method :: atom()
  @type uri :: binary() | URI.t()
  @type body :: binary() | map() | tuple()
  @type headers :: list()
  @type opts :: Keyword.t() | term()
  @type status :: non_neg_integer()
  @type reason :: term()

  @callback request(method, uri, body, headers, opts) ::
              {:ok, status, body, headers} | {:error, reason}

  @client_impl Application.compile_env(:gitlab_api, :http_impl, GitlabApi.HTTP.Finch)

  require Logger

  defmodule State do
    defstruct [
      :method,
      :uri,
      :path,
      :req_headers,
      :req_body,
      :opts,
      :params,
      :resp_body,
      :resp_headers,
      :status,
      :error
    ]
  end

  def request(method, path, params, opts) do
    %State{
      method: method,
      path: path,
      params: filter_params(params),
      opts: opts,
      req_headers: []
    }
    |> prepare_path()
    |> build_request_uri()
    |> build_request_headers()
    |> build_request_body()
    |> process_request()
    |> process_response()
  end

  defp process_request(%State{uri: %URI{} = uri} = state) do
    response =
      @client_impl.request(
        state.method,
        URI.to_string(uri),
        state.req_body,
        state.req_headers,
        state.opts
      )

    case response do
      {:ok, status, body, headers} ->
        %{state | status: status, resp_body: body, resp_headers: headers}

      {:error, reason} ->
        %{state | error: reason, status: 0}
    end
  end

  defp process_response(%State{status: code, resp_body: body}) when code in 200..299 do
    case Jason.decode(body) do
      {:ok, parsed} -> {:ok, parsed}
      {:error, _reason} -> {:ok, body}
    end
  end

  defp process_response(%State{status: code, resp_body: body}) when code in 400..499 do
    case Jason.decode(body) do
      {:ok, map} -> {:error, %{reason: map}}
      {:error, _reason} -> {:error, %{reason: body}}
    end
  end

  defp process_response(%State{status: code}) when code in 500..599 do
    {:error, %{reason: "service_unavailable"}}
  end

  defp process_response(%State{error: error}) do
    Logger.error("GitLab HTTP request failed: transport_error")
    {:error, %{reason: error}}
  end

  defp build_request_headers(%State{opts: opts, req_headers: headers} = state) do
    case Keyword.pop(opts, :api_token) do
      {nil, opts} ->
        %{state | req_headers: [{"PRIVATE-TOKEN", GitlabApi.auth_token()} | headers], opts: opts}

      {token, opts} ->
        %{state | req_headers: [{"PRIVATE-TOKEN", token} | headers], opts: opts}
    end
  end

  defp build_request_body(%State{method: method} = state) when method in [:get, :delete] do
    %{state | req_body: ""}
  end

  defp build_request_body(%State{} = state) do
    %{
      state
      | req_body: Jason.encode!(state.params),
        req_headers: [{"Content-Type", "application/json"} | state.req_headers]
    }
  end

  defp build_request_uri(%State{method: method} = state) when method in [:get, :delete] do
    query =
      state.params
      |> Enum.flat_map(fn
        {key, values} when is_list(values) ->
          Enum.map(values, &{"#{key}[]", &1})

        pair ->
          [pair]
      end)
      |> URI.encode_query()

    uri = build_uri(state.path)
    %{state | uri: %{uri | query: if(query == "", do: nil, else: query)}}
  end

  defp build_request_uri(%State{path: path} = state) do
    %{state | uri: build_uri(path)}
  end

  defp build_uri(path) do
    GitlabApi.host()
    |> Path.join(path)
    |> URI.parse()
  end

  # put path params like /service/:context/:resource_id
  defp prepare_path(%State{params: params, path: path} = state) do
    case get_path_keys(path) do
      [] ->
        state

      keys ->
        {path, params} = put_path_params(params, keys, path)
        %{state | path: path, params: params}
    end
  end

  defp put_path_params(source_params, ["_"], source_path) do
    path =
      source_path
      |> String.replace(":_", encode_path_param(source_params))
      |> String.trim_trailing("/")

    {path, %{}}
  end

  defp put_path_params(source_params, keys, source_path) do
    {path, params} =
      Enum.reduce(keys, {source_path, source_params}, fn key, {path, params} ->
        {value, params} = Map.pop(params, String.to_existing_atom(key), "")
        {String.replace(path, ":#{key}", encode_path_param(value)), params}
      end)

    {String.trim_trailing(path, "/"), params}
  end

  defp encode_path_param(value) do
    value
    |> to_string()
    |> URI.encode(&URI.char_unreserved?/1)
  end

  defp get_path_keys(path) do
    ~r/\/\:\w+/
    |> Regex.scan(path)
    |> Enum.take(3)
    |> List.flatten()
    |> Enum.map(fn k -> String.replace(k, "/:", "") end)
  end

  defp filter_params(params) when is_struct(params) do
    Map.from_struct(params) |> filter_map_params()
  end

  defp filter_params(params) when is_map(params) do
    filter_map_params(params)
  end

  defp filter_params(params) do
    params
  end

  defp filter_map_params(params) do
    for {_k, v} = p <- params, v != nil, into: %{}, do: p
  end
end
