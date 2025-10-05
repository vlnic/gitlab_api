defmodule GitlabApi.GroupSearch do
  use GitlabApi.API

  ## Implement https://docs.gitlab.com/api/search/#group-search

  action :projects,
    endpoint: {:get, "/api/v4/groups/:group/search"},
    params: [
      group: :integer,
      project: :string
    ],
    params_fn: fn(params) ->
      %{
        scope: "projects",
        search: params.project,
        group: Integer.to_string(params.group)
      }
    end
end
