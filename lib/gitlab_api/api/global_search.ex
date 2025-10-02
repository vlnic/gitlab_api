defmodule GitlabApi.GlobalSearch do
  use GitlabApi.API

  ## Based on https://docs.gitlab.com/api/search/#global-search

  action :users,
    endpoint: {:get, "/api/v4/search"},
    params: {:primitive, :string},
    params_fn: fn(username) ->
      %{scope: "users", search: username}
    end

  action :merge_requests,
    endpoint: {:get, "/api/v4/search"},
    params: {:primitive, :string},
    params_fn: fn(params) ->
      %{scope: "merge_requests", search: params}
    end

  action :issues,
    endpoint: {:get, "/api/v4/search"},
    params: {:primitive, :string},
    params_fn: fn(issue) ->
      %{scope: "issues", search: issue}
    end

  action :projects,
    endpoint: {:get, "/api/v4/search"},
    params: {:primitive, :string},
    params_fn: fn(project) ->
      %{scope: "projects", search: project}
    end

  action :milestones,
    endpoint: {:get, "/api/v4/search"},
    params: {:primitive, :string},
    params_fn: fn(milestone) ->
      %{scope: "milestones", search: milestone}
    end

  action :snippet_titles,
    endpoint: {:get, "/api/v4/search"},
    params: {:primitive, :string},
    params_fn: fn(title) ->
      %{scope: "snippet_titles", search: title}
    end

  action :wiki_blobs,
    endpoint: {:get, "/api/v4/search"},
    params: {:primitive, :string},
    params_fn: fn(blob) ->
      %{scope: "wiki_blobs", search: blob}
    end

  action :commits,
    endpoint: {:get, "/api/v4/search"},
    params: {:primitive, :string},
    params_fn: fn(commit_message) ->
      %{scope: "commits", search: commit_message}
    end

  action :blobs,
    endpoint: {:get, "/api/v4/search"},
    params: {:primitive, :string},
    params_fn: fn(blob) ->
      %{scope: "blobs", search: blob}
    end

  action :notes,
    endpoint: {:get, "/api/v4/search"},
    params: {:primitive, :string},
    params_fn: fn(str) ->
      %{scope: "notes", search: str}
    end
end
