defmodule GitlabApi.GlobalSearchTest do
  use GitlabApi.CommonCase

  describe "common global search" do
    test "users" do
      client_stub({:ok, 200, Jason.encode!([%{
        "id" => 123,
        "name" => "User Test",
        "username" => "user.test",
        "state" => "active",
        "avatar_url" => "",
        "web_url" => ""
      }]), []})

      assert {:ok, _response} = GitlabApi.GlobalSearch.request(%{
        search: "user.test",
        scope: "users",
        search_type: "basic"
      })

      assert_receive {:request_method, :get}
      assert_receive {:request_uri, "http://localhost/api/v4/search?scope=users&search=user.test&search_type=basic"}
      assert_receive {:request_body, ""}
      assert_receive {:request_headers, [{"PRIVATE-TOKEN", _token}]}
    end

    test "projects" do
      client_stub({:ok, 200, Jason.encode!([%{
        "id" => 6,
        "description" => "Nobis sed ipsam vero quod cupiditate veritatis hic.",
        "name" => "Flight",
        "name_with_namespace" => "Twitter / Flight",
        "path" => "flight",
        "path_with_namespace" => "twitter/flight",
        "created_at" => "2017-09-05T07:58:01.621Z",
        "default_branch" => "main",
        "tag_list" =>[],
        "topics" =>[],
        "ssh_url_to_repo" => "ssh://jarka@localhost:2222/twitter/flight.git",
        "http_url_to_repo" => "http://localhost:3000/twitter/flight.git",
        "web_url" => "http://localhost:3000/twitter/flight",
        "readme_url" => "http://localhost:3000/twitter/flight/-/blob/main/README.md",
        "avatar_url" => nil,
        "star_count" => 0,
        "forks_count" => 0,
        "last_activity_at" => "2018-01-31T09:56:30.902Z"
      }]), []})

      assert {:ok, _response} = GitlabApi.GlobalSearch.request(%{search: "flight", scope: "projects"})
      assert_receive {:request_method, :get}
      assert_receive {:request_uri, "http://localhost/api/v4/search?scope=projects&search=flight"}
      assert_receive {:request_body, ""}
      assert_receive {:request_headers, [{"PRIVATE-TOKEN", _token}]}
    end

    test "merge_requests" do
      client_stub({:ok, 200, Jason.encode!([[%{
        "id" => 56,
        "iid" => 8,
        "project_id" => 6,
        "title" => "Add first file",
        "description" => "This is a test MR to add file",
        "state" => "opened",
        "created_at" => "2018-01-22T14:21:50.830Z",
        "updated_at" => "2018-02-06T12:40:33.295Z",
        "target_branch" => "main",
        "source_branch" => "jaja-test",
        "upvotes" => 0,
        "downvotes" => 0,
        "author" => %{
          "id" => 1,
          "name" => "Administrator",
          "username" => "root",
          "state" => "active",
          "avatar_url" => "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
          "web_url" => "http://localhost:3000/root"
        },
        "assignee" => %{
          "id" => 5,
          "name" => "Jacquelyn Kutch",
          "username" => "abigail",
          "state" => "active",
          "avatar_url" => "https://www.gravatar.com/avatar/3138c66095ee4bd11a508c2f7f7772da?s=80&d=identicon",
          "web_url" => "http://localhost:3000/abigail"
        },
        "source_project_id" => 6,
        "target_project_id" => 6,
        "labels" => [
          "ruby",
          "tests"
        ],
        "draft" => false,
        "work_in_progress" => false,
        "milestone" => %{
          "id" => 13,
          "iid" => 3,
          "project_id" => 6,
          "title" => "v2.0",
          "description" => "Qui aut qui eos dolor beatae itaque tempore molestiae.",
          "state" => "active",
          "created_at" => "2017-09-05T07:58:29.099Z",
          "updated_at" => "2017-09-05T07:58:29.099Z",
          "due_date" => nil,
          "start_date" => nil
        },
        "merge_when_pipeline_succeeds" => false,
        "merge_status" => "can_be_merged",
        "sha" => "78765a2d5e0a43585945c58e61ba2f822e4d090b",
        "merge_commit_sha" => nil,
        "squash_commit_sha" => nil,
        "user_notes_count" => 0,
        "discussion_locked" => nil,
        "should_remove_source_branch" => nil,
        "force_remove_source_branch" => true,
        "web_url" => "http://localhost:3000/twitter/flight/merge_requests/8",
        "time_stats" => %{
          "time_estimate" => 0,
          "total_time_spent" => 0,
          "human_time_estimate" => nil,
          "human_total_time_spent" => nil
        }
      }]]), []})

      assert {:ok, _response} = GitlabApi.GlobalSearch.request(%{
        search: "file",
        scope: "merge_requests",
        order_by: "updated_at",
        sort: "desc",
        state: "open"
      })

      assert_receive {:request_method, :get}
      assert_receive {
        :request_uri,
        "http://localhost/api/v4/search?scope=merge_requests&state=open&sort=desc&search=file&order_by=updated_at"
      }
      assert_receive {:request_body, ""}
      assert_receive {:request_headers, [{"PRIVATE-TOKEN", _token}]}
    end

    test "milestones" do
      client_stub({:ok, 200, Jason.encode!([%{
        "id" => 44,
        "iid" => 1,
        "project_id" => 12,
        "title" => "next release",
        "description" => "Next release milestone",
        "state" => "active",
        "created_at" => "2018-02-06T12:43:39.271Z",
        "updated_at" => "2018-02-06T12:44:01.298Z",
        "due_date" => "2018-04-18",
        "start_date" => "2018-02-04"
      }]), []})

      assert {:ok, _response} = GitlabApi.GlobalSearch.request(%{scope: "milestones", search: "release"})
      assert_receive {:request_method, :get}
      assert_receive {:request_uri, "http://localhost/api/v4/search?scope=milestones&search=release"}
      assert_receive {:request_body, ""}
      assert_receive {:request_headers, [{"PRIVATE-TOKEN", _token}]}
    end
  end
end
