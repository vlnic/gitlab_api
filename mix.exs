defmodule GitlabApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :gitlab_api,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env),
      description: description()
    ]
  end

  def description do
    "Api Client for Gitlab " <>
    "https://docs.gitlab.com/api/rest/"
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {GitlabApi.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.20"},
      {:construct, "~> 3.0"},
      {:jason, "~> 1.4"},
      {:mox, ">= 0.0.0", only: [:dev, :test]}
    ]
  end
end
