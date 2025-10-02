import Config

config :gitlab_api,
  host: File.read!("gitlab_host"),
  token: File.read!("gitlab_token")
