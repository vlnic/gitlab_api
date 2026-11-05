defmodule GitlabApi.VersionTest do
  use GitlabApi.CommonCase, async: true

  test "requests and decodes the GitLab version" do
    response = %{"version" => "18.5.0", "revision" => "abc123"}
    client_stub({:ok, 200, Jason.encode!(response), []})

    assert GitlabApi.Version.version() == {:ok, response}
    assert_request(:get, "/api/v4/version")
  end
end
