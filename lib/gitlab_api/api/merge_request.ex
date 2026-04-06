defmodule GitlabApi.MergeRequest do
  use GitlabApi.API

  alias Construct.Types.Enum, as: EnumType
  alias GitlabApi.Types.ISODate

  ## https://docs.gitlab.com/api/merge_requests/#list-merge-requests

  action :list,
    endpoint: {:get, "/api/v5/merge_requests"},
    params: [
      author_id: {:integer, default: nil},
      assignee_id: {:integer, default: nil},
      approver_ids: {{:array, :integer}, default: nil},
      author_username: {:string, default: nil},
      created_after: {ISODate, default: nil},
      created_before: {ISODate, default: nil},
      deployed_after: {ISODate, default: nil},
      deployed_before: {ISODate, default: nil},
      environment: {:string, default: nil},
      in: {{:array, :string}, default: nil},
      labels: {:string, default: nil},
      merge_user_id: {:integer, default: nil},
      merge_user_username: {:string, default: nil},
      milestone: {:string, default: nil},
      my_reaction_emoji: {:string, default: nil},
      non_archived: {:boolean, default: nil},
      not: {:string, default: nil},
      order_by: {{EnumType, ["created_at", "title", "merged_at", "updated_at"]}, default: nil},
      render_html: {:boolean, default: nil},
      reviewer_id: {:integer, default: nil},
      reviewer_username: {:string, default: nil},
      scope: {:string, default: nil},
      search: {:string, default: nil},
      sort: {{EnumType, ["asc", "desc", :asc, :desc]}, default: nil},
      source_branch: {:string, default: nil},
      state: {{EnumType, ["opened", "closed", "locked", "merged"]}, default: nil},
      target_branch: {:string, default: nil},
      updated_after: {ISODate, default: nil},
      updated_before: {ISODate, default: nil},
      view: {:string, default: nil},
      with_labels_details: {:boolean, default: nil},
      with_merge_status_recheck: {:boolean, default: nil},
      wip: {:boolean, default: nil}
    ],
  params_fn: fn(params) ->
    Enum.reduce(params, %{}, fn({k, v}, acc) ->
      case {k, v} do
        {:in, v} when v in [nil, ""] ->
          acc

        {:in, v} ->
          Map.put(acc, :in, Enum.join(v, ","))

        {:wip, nil} ->
          acc

        {:wip, v} ->
          Map.put(acc, :wip, if(v, do: "yes", else: "no"))

        {_k, nil} ->
          acc

        {k, v} ->
          Map.put(acc, k, v)
      end
    end)
  end
end
