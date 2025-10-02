defmodule GitlabApi do
  def finch_name, do: GitlabApi.Finch

  def host, do: Application.get_env(:gitlab_api, :host)

  def auth_token, do: Application.get_env(:gitlab_api, :api_token)
end
