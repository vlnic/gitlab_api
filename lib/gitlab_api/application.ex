defmodule GitlabApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: GitlabApi.finch_name()}
    ]

    opts = [strategy: :one_for_one, name: GitlabApi.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
