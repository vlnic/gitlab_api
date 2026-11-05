defmodule GitlabApi.EventsTest do
  use GitlabApi.CommonCase, async: true

  describe "user_events/2" do
    test "requests user contributions with filters and pagination" do
      response = [%{"id" => 42, "action_name" => "pushed to"}]
      client_stub({:ok, 200, Jason.encode!(response), []})

      params = %{
        user_id: "123",
        action: "pushed",
        target_type: "project",
        before: ~D[2026-11-06],
        after: "2026-11-01",
        sort: :desc,
        page: "2",
        per_page: 50
      }

      assert GitlabApi.Events.user_events(params) == {:ok, response}

      assert_request(:get, "/api/v4/users/123/events", %{
        "action" => "pushed",
        "target_type" => "project",
        "before" => "2026-11-06",
        "after" => "2026-11-01",
        "sort" => "desc",
        "page" => "2",
        "per_page" => "50"
      })
    end

    test "omits optional parameters" do
      client_stub({:ok, 200, "[]", []})

      assert GitlabApi.Events.user_events(%{user_id: 123}) == {:ok, []}
      assert_request(:get, "/api/v4/users/123/events")
    end

    test "rejects missing user and invalid dates without sending a request" do
      assert GitlabApi.Events.user_events() == {:error, %{user_id: :missing}}

      assert GitlabApi.Events.user_events(%{user_id: 123, before: "2026-02-30"}) ==
               {:error, %{before: :invalid}}
    end

    test "rejects unsupported actions" do
      assert {:error, %{action: error}} =
               GitlabApi.Events.user_events(%{user_id: 123, action: "unknown"})

      assert error[:passed_value] == "unknown"
    end
  end
end
