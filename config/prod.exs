import Config

config :gitlab_api,
  host: System.get_env("GITLAB_HOST", "http://localhost"),
  api_token: System.get_env("GITLAB_TOKEN")
