defmodule GitlabApi.GlobalSearch do
  use GitlabApi.API

  alias Construct.Types.Enum

  ## Implement https://docs.gitlab.com/api/search/#global-search

  @scopes ~w(
    projects issues merge_requests
    milestones snippet_titles users
    wiki_blobs commits blobs notes
  )

  action :request,
    endpoint: {:get, "/api/v4/search"},
    params: [
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
