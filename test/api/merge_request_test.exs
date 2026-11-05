defmodule GitlabApi.MergeRequestTest do
  use GitlabApi.CommonCase, async: true

  describe "list/2" do
    test "requests merge requests using API v4" do
      response = [%{"id" => 56, "iid" => 8, "state" => "opened"}]
      client_stub({:ok, 200, Jason.encode!(response), []})

      assert GitlabApi.MergeRequest.list() == {:ok, response}
      assert_request(:get, "/api/v4/merge_requests")
    end

    test "sends pagination with filters and forwards client options" do
      response = [%{"id" => 56, "iid" => 8, "state" => "opened"}]
      client_stub({:ok, 200, Jason.encode!(response), []})
      params = %{page: 2, per_page: 50, state: "opened"}

      assert GitlabApi.MergeRequest.list(params, receive_timeout: 5000) == {:ok, response}

      assert_request(
        :get,
        "/api/v4/merge_requests",
        %{
          "page" => "2",
          "per_page" => "50",
          "state" => "opened"
        },
        receive_timeout: 5000
      )
    end

    test "casts pagination from string parameters" do
      client_stub({:ok, 200, "[]", []})

      assert GitlabApi.MergeRequest.list(%{"page" => "003", "per_page" => "020"}) == {:ok, []}
      assert_request(:get, "/api/v4/merge_requests", %{"page" => "3", "per_page" => "20"})
    end

    test "omits unset pagination parameters" do
      client_stub({:ok, 200, "[]", []})

      assert GitlabApi.MergeRequest.list(%{page: 2, per_page: nil}) == {:ok, []}
      assert_request(:get, "/api/v4/merge_requests", %{"page" => "2"})
    end

    test "rejects invalid pagination before sending a request" do
      assert {:error, %{page: :invalid, per_page: :invalid}} =
               GitlabApi.MergeRequest.list(%{page: "invalid", per_page: "invalid"})
    end

    test "transforms search fields, dates and wip filters" do
      client_stub({:ok, 200, "[]", []})

      params = %{
        search: "fix & review",
        in: ["title", "description"],
        wip: true,
        state: "opened",
        sort: :desc,
        created_after: ~D[2026-11-01]
      }

      assert GitlabApi.MergeRequest.list(params) == {:ok, []}

      assert_request(:get, "/api/v4/merge_requests", %{
        "search" => "fix & review",
        "in" => "title,description",
        "wip" => "yes",
        "state" => "opened",
        "sort" => "desc",
        "created_after" => "2026-11-01"
      })
    end

    test "transforms false wip to no" do
      client_stub({:ok, 200, "[]", []})

      assert GitlabApi.MergeRequest.list(%{wip: false}) == {:ok, []}
      assert_request(:get, "/api/v4/merge_requests", %{"wip" => "no"})
    end

    test "encodes array filters as repeated query parameters" do
      client_stub({:ok, 200, "[]", []})

      assert GitlabApi.MergeRequest.list(%{approver_ids: [12, 34]}) == {:ok, []}
      assert_receive {:request_uri, uri}

      assert URI.parse(uri).path == "/api/v4/merge_requests"

      assert Enum.to_list(URI.query_decoder(URI.parse(uri).query)) ==
               [{"approver_ids[]", "12"}, {"approver_ids[]", "34"}]
    end

    test "rejects unsupported states without sending a request" do
      assert {:error, %{state: error}} = GitlabApi.MergeRequest.list(%{state: "unknown"})
      assert error[:passed_value] == "unknown"
    end
  end
end
