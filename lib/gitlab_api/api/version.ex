defmodule GitlabApi.Version do
  use GitlabApi.API

  action :version,
    endpoint: {:get, "/api/v4/version"}
end
