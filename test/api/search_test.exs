defmodule GitlabApi.SearchTest do
  use GitlabApi.CommonCase, async: true

  @searches [
    {GitlabApi.GlobalSearch, %{}, "/api/v4/search"},
    {GitlabApi.GroupSearch, %{group: 3}, "/api/v4/groups/3/search"},
    {GitlabApi.ProjectSearch, %{project: 6}, "/api/v4/projects/6/search"}
  ]

  for {module, path_params, path} <- @searches do
    describe inspect(module) do
      test "returns decoded search results and serializes filters" do
        response = [%{"id" => 42, "title" => "Fix search"}]
        client_stub({:ok, 200, Jason.encode!(response), []})

        params =
          Map.merge(unquote(Macro.escape(path_params)), %{
            search: "fix & review",
            scope: "issues",
            search_type: "advanced",
            confidential: false,
            sort: :desc,
            order_by: "updated_at"
          })

        assert unquote(module).request(params) == {:ok, response}

        assert_request(:get, unquote(path), %{
          "search" => "fix & review",
          "scope" => "issues",
          "search_type" => "advanced",
          "confidential" => "false",
          "sort" => "desc",
          "order_by" => "updated_at"
        })
      end

      test "returns an empty result list" do
        client_stub({:ok, 200, "[]", []})

        params =
          Map.merge(unquote(Macro.escape(path_params)), %{search: "missing", scope: "users"})

        assert unquote(module).request(params) == {:ok, []}
        assert_request(:get, unquote(path), %{"search" => "missing", "scope" => "users"})
      end

      test "rejects missing search terms without sending a request" do
        params = Map.put(unquote(Macro.escape(path_params)), :scope, "users")

        assert unquote(module).request(params) == {:error, %{search: :missing}}
      end

      test "rejects unsupported scopes without sending a request" do
        params =
          Map.merge(unquote(Macro.escape(path_params)), %{search: "test", scope: "unknown"})

        assert {:error, %{scope: error}} = unquote(module).request(params)
        assert error[:passed_value] == "unknown"
      end

      test "rejects invalid sorting and search types" do
        params =
          Map.merge(unquote(Macro.escape(path_params)), %{
            search: "test",
            scope: "users",
            sort: "unknown",
            search_type: "unknown"
          })

        assert {:error, %{sort: _, search_type: _}} = unquote(module).request(params)
      end
    end
  end

  test "requires the group and project identifiers" do
    assert GitlabApi.GroupSearch.request(%{search: "test", scope: "users"}) ==
             {:error, %{group: :missing}}

    assert GitlabApi.ProjectSearch.request(%{search: "test", scope: "users"}) ==
             {:error, %{project: :missing}}
  end
end
