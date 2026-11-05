defmodule GitlabApi.PipelineTest do
  use GitlabApi.CommonCase, async: true

  @get_requests [
    {:all, %{project: 6}, "/api/v4/projects/6/pipelines", [%{"id" => 42}]},
    {:get, %{project: "6", id: 42}, "/api/v4/projects/6/pipelines/42", %{"id" => 42}},
    {:variables, %{id: 6, pipeline_id: 42}, "/api/v4/projects/6/pipelines/42/variables",
     [%{"key" => "ENV", "value" => "test"}]},
    {:test_report, %{id: 6, pipeline_id: 42}, "/api/v4/projects/6/pipelines/42/test_report",
     %{"total_count" => 5}},
    {:test_report_summary, %{id: 6, pipeline_id: 42},
     "/api/v4/projects/6/pipelines/42/test_report_summary", %{"total" => %{"count" => 5}}}
  ]

  for {action, params, path, response} <- @get_requests do
    test "#{action} requests the expected endpoint and decodes the response" do
      response = unquote(Macro.escape(response))
      client_stub({:ok, 200, Jason.encode!(response), []})

      params = unquote(Macro.escape(params))
      assert {:ok, ^response} = apply(GitlabApi.Pipeline, unquote(action), [params])

      assert_request(:get, unquote(path))
    end
  end

  test "all encodes a namespaced project and serializes filters" do
    client_stub({:ok, 200, "[]", []})

    params = %{
      project: "team/flight",
      ref: "feature/search",
      status: "success",
      sort: :desc,
      yaml_errors: false,
      updated_after: "2026-11-01T12:30:00Z"
    }

    assert GitlabApi.Pipeline.all(params) == {:ok, []}

    assert_request(:get, "/api/v4/projects/team%2Fflight/pipelines", %{
      "ref" => "feature/search",
      "status" => "success",
      "sort" => "desc",
      "yaml_errors" => "false",
      "updated_after" => "2026-11-01T12:30:00Z"
    })
  end

  test "latest uses the project ID in the path and page in the query" do
    response = %{"id" => 42, "ref" => "main"}
    client_stub({:ok, 200, Jason.encode!(response), []})

    assert GitlabApi.Pipeline.latest(%{project: 6, ref: "main", page: 2, per_page: 50}) ==
             {:ok, response}

    assert_request(:get, "/api/v4/projects/6/pipelines/latest", %{
      "ref" => "main",
      "page" => "2",
      "per_page" => "50"
    })
  end

  test "latest allows the default branch" do
    client_stub({:ok, 200, "{\"id\":42}", []})

    assert GitlabApi.Pipeline.latest(%{project: 6}) == {:ok, %{"id" => 42}}
    assert_request(:get, "/api/v4/projects/6/pipelines/latest", %{"page" => "1"})
  end

  test "create sends variables in the JSON body without the project ID" do
    response = %{"id" => 42, "status" => "pending"}
    client_stub({:ok, 201, Jason.encode!(response), []})

    params = %{
      id: 6,
      ref: "main",
      variables: [%{key: "ENV", value: "test"}]
    }

    assert GitlabApi.Pipeline.create(params) == {:ok, response}

    assert_request(:post, "/api/v4/projects/6/pipeline", %{
      "ref" => "main",
      "variables" => [%{"key" => "ENV", "value" => "test"}]
    })
  end

  for {action, suffix} <- [retry: "retry", cancel_all: "cancel"] do
    test "#{action} posts to the expected pipeline endpoint" do
      response = %{"id" => 42}
      client_stub({:ok, 200, Jason.encode!(response), []})

      assert apply(GitlabApi.Pipeline, unquote(action), [%{id: 6, pipeline_id: 42}]) ==
               {:ok, response}

      assert_request(:post, "/api/v4/projects/6/pipelines/42/" <> unquote(suffix))
    end
  end

  test "delete sends an empty body" do
    client_stub({:ok, 204, "", []})

    assert GitlabApi.Pipeline.delete(%{id: 6, pipeline_id: 42}) == {:ok, ""}
    assert_request(:delete, "/api/v4/projects/6/pipelines/42")
  end

  test "update_metadata sends the new name as JSON" do
    response = %{"id" => 42, "name" => "Release build"}
    client_stub({:ok, 200, Jason.encode!(response), []})

    assert GitlabApi.Pipeline.update_metadata(%{id: 6, pipeline_id: 42, name: "Release build"}) ==
             {:ok, response}

    assert_request(:put, "/api/v4/projects/6/pipelines/42/metadata", %{"name" => "Release build"})
  end

  test "rejects missing IDs, invalid statuses and invalid datetimes before HTTP" do
    assert GitlabApi.Pipeline.get(%{project: 6}) == {:error, %{id: :missing}}
    assert GitlabApi.Pipeline.latest(%{ref: "main"}) == {:error, %{project: :missing}}
    assert {:error, %{status: _}} = GitlabApi.Pipeline.all(%{project: 6, status: "unknown"})

    assert GitlabApi.Pipeline.all(%{project: 6, updated_after: "invalid"}) ==
             {:error, %{updated_after: :invalid}}
  end
end
