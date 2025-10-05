defmodule GitlabApi.ProjectSearch do
  use GitlabApi.API

  alias Construct.Types.Enum
  alias GitlabApi.Types.StringOrInteger

  ## https://docs.gitlab.com/api/search/#project-search

  @scopes ~w(
    projects issues merge_requests
    milestones snippet_titles users
    wiki_blobs commits blobs notes
  )

  action :request,
    endpoint: {:get, "/api/v4/projects/:project/search"},
    params: [
      project: StringOrInteger,
      search: :string,
      scope: {Enum, @scopes},
      search_type: {{Enum, ["basic", "advanced", "zoekt"]}, default: nil},
      confidential: {:boolean, default: nil},
      order_by: {{Enum, ["created_at", "updated_at"]}, default: nil},
      sort: {{Enum, ["asc", "desc", :asc, :desc]}, default: nil},
      state: {:string, default: nil},
      fields: {{Enum, ["title", "issues", "merge_requests"]}, default: nil}
    ]
end
