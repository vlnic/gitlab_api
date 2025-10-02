import Config

config :gitlab_api,
  connect_pool: 10,
  timeout: 60_000

import_config("#{Mix.env()}.exs")
