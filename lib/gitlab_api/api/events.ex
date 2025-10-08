defmodule GitlabApi.Events do
  use GitlabApi.API

  alias Construct.Types.Enum
  alias GitlabApi.Types.ISODate
  alias GitlabApi.Types.StringOrInteger

  @user_contribution_events ~w(
    approved closed commented created
    destroyed expired joined left
    merged pushed reopened updated
  )

  @user_target_type ~w(
    epic issue merge_request milestone note
    project snippet user
  )

  action :user_events,
    endpoint: {:get, "/api/v4/users/:user_id/events"},
    params: [
      user_id: StringOrInteger,
      action: {{Enum, @user_contribution_events}, default: nil},
      target_type: {{Enum, @user_target_type}, default: nil},
      before: {ISODate, default: nil},
      after: {ISODate, default: nil},
      sort: {{Enum, ["asc", "desc", :asc, :desc]}, default: nil},
      page: {:integer, default: nil},
      per_page: {:integer, default: nil}
    ]
end
