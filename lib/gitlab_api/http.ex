defmodule GitlabApi.HTTP do
  @type method :: atom()
  @type uri :: binary() | URI.t()
  @type body :: binary() | map() | tuple()
  @type headers :: list()
  @type opts :: Keyword.t() | term()
  @type status :: non_neg_integer()
  @type reason :: term()

  @callback request(method, uri, body, headers, opts) :: {:ok, status, body, headers} | {:error, reason}

  @client_impl Application.compile_env(:gitlab_api, :http_impl, GitlabApi.HTTP.Finch)

  require Logger

  defmodule State do
    defstruct [
      :method, :uri, :path, :req_headers, :req_body,
      :opts, :params, :resp_body, :resp_headers, :status,
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

  defp process_request(%State{
    method: method,
    uri: %URI{} = uri,
    req_body: body,
    req_headers: headers,
    opts: opts
  } = state) do
    case @client_impl.request(method, URI.to_string(uri), body, headers, opts) do
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
  defp process_response(%State{error: error} = state) do
    Logger.warning("failed request with state: #{inspect state, pretty: true}")
    {:error, %{reason: error}}
  end

  defp build_request_headers(%State{opts: opts, req_headers: headers} = state) do
    token =
      case Keyword.fetch(opts, :api_token) do
        {:ok, token} ->
          token

        _ ->
          GitlabApi.auth_token()
      end

    %{state | req_headers: [{"PRIVATE-TOKEN", token} | headers]}
  end

  defp build_request_body(%State{method: method} = state) when method in [:get, :delete] do
    %{state | req_body: ""}
  end

  defp build_request_body(%State{} = state) do
    %{state | req_body: Jason.encode!(state.params)}
  end

  defp build_request_uri(%State{method: method} = state) when method in [:get, :delete] do
    {_, path} =
      state.params
      |> Map.to_list()
      |> Enum.reduce({0, state.path}, fn({k, v}, {index, acc}) ->
        case index do
          0 ->
            {1, "#{acc}?#{k}=#{v}"}

          _ ->
            {1, "#{acc}&#{k}=#{v}"}
        end
      end)

    %{state | uri: build_uri(path)}
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
      |> String.replace(":_", source_params)
      |> String.trim_trailing("/")

    {path, %{}}
  end
  defp put_path_params(source_params, keys, source_path) do
    {path, params} =
      Enum.reduce(keys, {source_path, source_params}, fn(key, {path, params}) ->
        {value, params} = Map.pop(params, String.to_existing_atom(key), "")
        {String.replace(path, ":#{key}", "#{value}"), params}
      end)

    {String.trim_trailing(path, "/"), params}
  end

  defp get_path_keys(path) do
    ~r/\/\:\w+/
    |> Regex.scan(path)
    |> Enum.take(3)
    |> List.flatten()
    |> Enum.map(fn(k) -> String.replace(k, "/:", "") end)
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
