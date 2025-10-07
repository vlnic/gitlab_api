import Config

config :gitlab_api,
  host: System.get_env("JIRA_HOST", "http://localhost"),
  api_token: System.get_env("JIRA_TOKEN")
