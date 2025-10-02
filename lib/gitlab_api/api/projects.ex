defmodule GitlabApi.Projects do
  use GitlabApi.API

  action :get,
    endpoint: {:get, "/api/v4/projects/:_"},
    params: {:primitive, :integer}
end
