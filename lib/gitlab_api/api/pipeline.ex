defmodule GitlabApi.Pipeline do
  use GitlabApi.API

  alias Construct.Types.Enum
  alias GitlabApi.Types.ISODateTIme
  alias GitlabApi.Types.StringOrInteger

  @status_type ~w(
    created waiting_for_resource
    preparing pending running
    success failed canceled
    skipped manual scheduled
  )

  ## https://docs.gitlab.com/api/pipelines/#list-project-pipelines

  action :all,
    endpoint: {:get, "/projects/:project/pipelines"},
    params: [
      project: StringOrInteger,
      name: {:string, default: nil},
      order_by: {{Enum, ["id", "status", "ref", "updated_at", "user_id"]}, default: nil},
      ref: {:string, default: nil},
      scope: {{Enum, ["running", "pending", "finished", "branches", "tags"]}, default: nil},
      sha: {:string, default: nil},
      sort: {{Enum, ["asc", "desc", :asc, :desc]}, default: nil},
      source: {:string, default: nil},
      status: {{Enum, @status_type}, default: nil},
      updated_after: {ISODateTIme, default: nil},
      updated_before: {ISODateTIme, default: nil},
      created_after: {ISODateTIme, default: nil},
      created_before: {ISODateTIme, default: nil},
      username: {:string, default: nil},
      yaml_errors: {:boolean, default: nil}
    ]

  ## https://docs.gitlab.com/api/pipelines/#get-a-single-pipeline

  action :get,
    endpoint: {:get, "/projects/:project/pipelines/:id"},
    params: [
      project: StringOrInteger,
      id: :integer
    ]

  ## https://docs.gitlab.com/api/pipelines/#get-the-latest-pipeline

  action :latest,
    endpoint: {:get, "/projects/:page/pipelines/latest"},
    params: [
      ref: :string,
      page: {:integer, default: 1},
      per_page: {:integer, default: nil}
    ]

  ## https://docs.gitlab.com/api/pipelines/#get-variables-for-a-pipeline

  action :variables,
    endpoint: {:get, "/projects/:id/pipelines/:pipeline_id/variables"},
    params: [
      id: StringOrInteger,
      pipeline_id: :integer
    ]
end
