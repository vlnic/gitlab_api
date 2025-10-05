import Config

config :gitlab_api,
  host: "http://localhost",
  api_token: "secrettoken",
  http_impl: GitlabApi.HTTP.ClientMock
