# GitlabApi

An Elixir client for the GitLab API.

## Named contexts

Store multiple GitLab connections and select one for each request:

```elixir
:ok = GitlabApi.Contexts.put("work",
  host: "https://gitlab.company.com",
  api_token: token
)

GitlabApi.Projects.get(123, context: "work")
GitlabApi.Version.version(%{}, context: "work")

# Override the token for a single request.
GitlabApi.Projects.get(123, context: "work", api_token: other_token)

{:ok, %{host: host, api_token: token}} = GitlabApi.Contexts.fetch("work")
:ok = GitlabApi.Contexts.delete("work")
```

`put/2` creates or replaces a connection. Names may be nonempty strings or
existing non-nil atoms; use strings for dynamic names. Both `:host` and
`:api_token` must be nonempty strings. Invalid configuration returns
`{:error, :invalid_context}` and leaves the existing connection intact.
Deleting an unknown name returns `:ok`; fetching one returns
`{:error, :not_found}`.

Requests without `:context` use the application's `:host` and `:api_token`
configuration. Requests selecting an unknown name return
`{:error, %{reason: {:context_not_found, name}}}` without sending an HTTP
request. An explicitly supplied `:api_token` takes precedence over the stored
token. Each request resolves its host and token together once, so concurrent
updates cannot mix different versions of a connection.

The application supervises the context store. Writes are synchronous, and
reads access a protected ETS table directly. Connections are local to the
current node and are lost when the store or application restarts; register
them again on startup if needed. During store downtime, `fetch/1` returns
`{:error, :unavailable}` and requests selecting a context return
`{:error, %{reason: :contexts_unavailable}}`.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `gitlab_api` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gitlab_api, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/gitlab_api>.

