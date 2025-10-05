defmodule GitlabApi.GroupSearchTest do
  use GitlabApi.CommonCase

  describe "common group search" do
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
        "tag_list" => [],
        "topics" => [],
        "ssh_url_to_repo" => "ssh://jarka@localhost:2222/twitter/flight.git",
        "http_url_to_repo" => "http://localhost:3000/twitter/flight.git",
        "web_url" => "http://localhost:3000/twitter/flight",
        "readme_url" => "http://localhost:3000/twitter/flight/-/blob/main/README.md",
        "avatar_url" => nil,
        "star_count" => 0,
        "forks_count" => 0,
        "last_activity_at" => "2018-01-31T09:56:30.902Z"
      }]), []})

      assert {:ok, _response} = GitlabApi.GroupSearch.request(%{group: 3, search: "flight", scope: "projects"})
      assert_receive {:request_method, :get}
      assert_receive {:request_uri, "http://localhost/api/v4/groups/3/search?scope=projects&search=flight"}
      assert_receive {:request_body, ""}
      assert_receive {:request_headers, [{"PRIVATE-TOKEN", _token}]}
    end
  end
end
