defmodule GitlabApi.ProjectSearchTest do
  use GitlabApi.CommonCase

  describe "commo project search" do
    test "issues" do
      client_stub({:ok, 200, Jason.encode!([%{
        "id" => 83,
        "iid" => 1,
        "project_id" => 12,
        "title" => "Add file",
        "description" => "Add first file",
        "state" => "opened",
        "created_at" => "2018-01-24T06:02:15.514Z",
        "updated_at" => "2018-02-06T12:36:23.263Z",
        "closed_at" => nil,
        "labels" =>[],
        "milestone" => nil,
        "assignees" => [%{
          "id" => 20,
          "name" => "Ceola Deckow",
          "username" => "sammy.collier",
          "state" => "active",
          "avatar_url" => "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
          "web_url" => "http://localhost:3000/sammy.collier"
        }],
        "author" => %{
          "id" => 1,
          "name" => "Administrator",
          "username" => "root",
          "state" => "active",
          "avatar_url" => "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
          "web_url" => "http://localhost:3000/root"
        },
        "assignee" => %{
          "id" => 20,
          "name" => "Ceola Deckow",
          "username" => "sammy.collier",
          "state" => "active",
          "avatar_url" => "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
          "web_url" => "http://localhost:3000/sammy.collier"
        },
        "user_notes_count" => 0,
        "upvotes" => 0,
        "downvotes" => 0,
        "due_date" => nil,
        "confidential" => false,
        "discussion_locked" => nil,
        "web_url" => "http://localhost:3000/h5bp/7bp/subgroup-prj/issues/1",
        "time_stats" => %{
          "time_estimate" => 0,
          "total_time_spent" => 0,
          "human_time_estimate" => nil,
          "human_total_time_spent" => nil
        }
      }]), []})

      assert {:ok, _response} = GitlabApi.ProjectSearch.request(%{project: 12, scope: "issues", search: "file"})
      assert_receive {:request_method, :get}
      assert_receive {:request_uri, "http://localhost/api/v4/projects/12/search?scope=issues&search=file"}
      assert_receive {:request_body, ""}
      assert_receive {:request_headers, [{"PRIVATE-TOKEN", _token}]}
    end
  end
end
