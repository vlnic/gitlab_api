defmodule GitlabApi.Users do
  use GitlabApi.API

  alias GitlabApi.Types.ISODateTIme

  ## https://docs.gitlab.com/api/users/#list-users

  action :list,
    endpoint: {:get, "/users"},
    params: [
      username: {:string, default: nil},
      public_email: {:string, default: nil},
      search: {:string, default: nil},
      active: {:boolean, default: nil},
      external: {:boolean, default: nil},
      blocked: {:boolean, default: nil},
      created_after: {ISODateTIme, default: nil},
      created_before: {ISODateTIme, default: nil},
      exclude_active: {:boolean, default: nil},
      exclude_external: {:boolean, default: nil},
      exclude_humans: {:boolean, default: nil},
      exclude_internal: {:boolean, default: nil},
      without_project_bots: {:boolean, default: nil},
      saml_provider_id: {:integer, default: nil}
    ]
end
