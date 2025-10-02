defmodule GitlabApi.Projects.V4 do
  use GitlabApi.API

  action :get,
    endpoint: {:get, "/api/v4/projects/:_"},
    params: {:primitive, :integer}
end
