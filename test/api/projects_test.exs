defmodule GitlabApi.ProjectsTest do
  use GitlabApi.CommonCase, async: true

  describe "get/2" do
    test "requests a project by its integer ID" do
      response = %{"id" => 6, "name" => "Flight"}
      client_stub({:ok, 200, Jason.encode!(response), []})

      assert GitlabApi.Projects.get(6) == {:ok, response}
      assert_request(:get, "/api/v4/projects/6")
    end

    test "casts a numeric string ID" do
      client_stub({:ok, 200, "{\"id\":6}", []})

      assert GitlabApi.Projects.get("6") == {:ok, %{"id" => 6}}
      assert_request(:get, "/api/v4/projects/6")
    end

    test "rejects an invalid ID without sending a request" do
      assert GitlabApi.Projects.get("invalid") ==
               {:error, {:primitive_type_error, "invalid"}}
    end
  end
end
