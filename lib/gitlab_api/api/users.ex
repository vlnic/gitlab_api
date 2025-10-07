defmodule GitlabApi.Users do
  use GitlabApi.API

  alias Construct.Types.Enum
  alias GitlabApi.Types.ISODateTIme
  alias GitlabApi.Types.StringOrInteger

  @status_intervals ~w(
    30_minutes 3_hours 8_hours
    1_day 3_days 7_days 30_days
  )

  ## https://docs.gitlab.com/api/users/#list-users

  action :list,
    endpoint: {:get, "/api/v4/users"},
    params: [
      username: {:string, default: nil},
      public_email: {:string, default: nil},
      search: {:string, default: nil},
      active: {:boolean, default: nil},
      external: {:boolean, default: nil},
      extern_uid: {:string, default: nil},
      blocked: {:boolean, default: nil},
      created_after: {ISODateTIme, default: nil},
      created_before: {ISODateTIme, default: nil},
      exclude_active: {:boolean, default: nil},
      exclude_external: {:boolean, default: nil},
      exclude_humans: {:boolean, default: nil},
      exclude_internal: {:boolean, default: nil},
      without_project_bots: {:boolean, default: nil},
      saml_provider_id: {:integer, default: nil},
      provider: {:string, default: nil},
      order_by: {{Enum, ["id", "name", "username", "created_at", "updated_at"]}, default: nil},
      sort: {{Enum, ["asc", "desc", :asc, :desc]}, default: nil},
      two_factor: {{Enum, ["enabled", "disabled", :enabled, :disabled]}, default: nil},
      without_projects: {:boolean, default: nil},
      admins: {:boolean, default: nil},
      skip_ldap: {:boolean, default: nil}
    ]

  ## https://docs.gitlab.com/api/users/#get-a-single-user

  action :get,
    endpoint: {:get, "/api/v4/users/:_"},
    params: {:primitive, :integer}

  ## https://docs.gitlab.com/api/users/#as-a-regular-user-2

  action :self,
    endpoint: {:get, "/api/v4/user"},
    params: [sudo: {:integer, default: nil}]

  ## https://docs.gitlab.com/api/users/#create-a-user

  action :create,
    endpoint: {:post, "/api/v4/users"},
    params: [
      username: :string,
      name: :string,
      email: :string,
      password: {:string, default: nil},
      admin: {:boolean, default: nil},
      auditor: {:boolean, default: nil},
      avatar: {:string, default: nil},
      bio: {:string, default: nil},
      can_create_group: {:boolean, default: nil},
      color_scheme_id: {StringOrInteger, default: nil},
      commit_email: {:string, default: nil},
      extern_uid: {:string, default: nil},
      external: {:boolean, default: nil},
      extra_shared_runners_minutes_limit: {:boolean, default: nil},
      force_random_password: {:boolean, default: nil},
      group_id_for_saml: {StringOrInteger, default: nil},
      linkedin: {:string, default: nil},
      location: {:string, defualt: nil},
      note: {:string, default: nil},
      organization: {:string, default: nil},
      private_profile: {:boolean, default: nil},
      projects_limit: {:integer, default: nil},
      pronouns: {:string, default: nil},
      provider: {:string, default: nil},
      public_email: {:string, default: nil},
      reset_password: {:boolean, default: nil},
      shared_runners_minutes_limit: {:integer, default: nil},
      skip_confirmation: {:boolean, default: nil},
      theme_id: {:string, default: nil},
      twitter: {:string, default: nil},
      discord: {:string, default: nil},
      github: {:string, default: nil},
      view_diffs_file_by_file: {:boolean, default: nil},
      website_url: {:string, default: nil}
    ]

  ## https://docs.gitlab.com/api/users/#modify-a-user

  action :update,
    endpoint: {:put, "/api/v4/users/:id"},
    params: [
      id: StringOrInteger,
      admin: {:boolean, default: nil},
      auditor: {:boolean, default: nil},
      avatar: {:string, default: nil},
      bio: {:string, default: nil},
      can_create_group: {:boolean, default: nil},
      color_scheme_id: {StringOrInteger, default: nil},
      commit_email: {:string, default: nil},
      email: {:string, default: nil},
      extern_uid: {:string, default: nil},
      external: {:boolean, default: nil},
      extra_shared_runners_minutes_limit: {:integer, default: nil},
      group_id_for_saml: {:integer, default: nil},
      linkedin: {:string, default: nil},
      location: {:string, defualt: nil},
      note: {:string, default: nil},
      organization: {:string, default: nil},
      name: {:string, default: nil},
      password: {:string, default: nil},
      private_profile: {:boolean, default: nil},
      projects_limit: {:integer, default: nil},
      pronouns: {:string, default: nil},
      provider: {:string, default: nil},
      public_email: {:string, default: nil},
      shared_runners_minutes_limit: {:integer, default: nil},
      skip_reconfirmation: {:boolean, default: nil},
      theme_id: {:string, default: nil},
      twitter: {:string, default: nil},
      discord: {:string, default: nil},
      github: {:string, default: nil},
      username: {:string, default: nil},
      view_diffs_file_by_file: {:boolean, default: nil},
      website_url: {:string, default: nil}
    ]

  ## https://docs.gitlab.com/api/users/#delete-a-user

  action :delete,
    endpoint: {:delete, "/api/v4/users/:id"},
    params: [
      id: :integer,
      hard_delete: {:boolean, default: nil}
    ]

  ## https://docs.gitlab.com/api/users/#get-your-user-status

  action :self_status,
    endpoint: {:get, "/api/v4/user/status"}

  ## https://docs.gitlab.com/api/users/#get-the-status-of-a-user

  action :get_status,
    endpoint: {:get, "/api/v4/users/:_/status"},
    params: {:primitive, StringOrInteger}

  ## https://docs.gitlab.com/api/users/#set-your-user-status

  action :set_self_status,
    endpoint: {:put, "/api/v4/user/status"},
    params: [
      emoji: {:string, default: nil},
      message: {:string, default: nil},
      availability: {{Enum, ["busy", "not_set"]}, default: nil},
      clear_status_after: {{Enum, @status_intervals}, default: nil}
    ]

  ## https://docs.gitlab.com/api/users/#get-your-user-preferences

  action :self_preferences,
    endpoint: {:get, "/api/v4/user/preferences"}

  ## https://docs.gitlab.com/api/users/#update-your-user-preferences

  action :update_self_preferences,
    endpoint: {:put, "/api/v4/user/preferences"},
    params: [
      view_diffs_file_by_file: :boolean,
      show_whitespace_in_diffs: :boolean,
      pass_user_identities_to_ci_jwt: :boolean
    ]

  ## https://docs.gitlab.com/api/users/#get-a-count-of-your-assigned-issues-merge-requests-and-reviews

  action :self_counts,
    endpoint: {:get, "/api/v4/user_counts"}

  ## https://docs.gitlab.com/api/users/#get-a-count-of-a-users-projects-groups-issues-and-merge-requests

  action :user_counts,
    endpoint: {:get, "/api/v4/users/:_/associations_count"},
    params: {:primitive, :integer}

  ## https://docs.gitlab.com/api/users/#list-a-users-activity

  action :activities,
    endpoint: {:get, "/api/v4/user/activities"},
    params: [from: {ISODateTIme, default: nil}]

  ## https://docs.gitlab.com/api/users/#list-projects-and-groups-that-a-user-is-a-member-of

  action :list_projects_and_groups,
    endpoint: {:get, "/api/v4/users/:id/memberships"},
    params: [
      id: :integer,
      type: {{Enum, ["Project", "Namespace"]}, default: nil}
    ]
end
