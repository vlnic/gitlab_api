defmodule GitlabApi.UsersTest do
  use GitlabApi.CommonCase, async: true

  @get_requests [
    {:list, %{}, "/api/v4/users", %{}, [%{"id" => 123, "username" => "user.test"}]},
    {:get, 123, "/api/v4/users/123", %{}, %{"id" => 123, "username" => "user.test"}},
    {:self, %{sudo: 123}, "/api/v4/user", %{"sudo" => "123"}, %{"id" => 123}},
    {:self_status, %{}, "/api/v4/user/status", %{}, %{"message" => "Reviewing code"}},
    {:get_status, "user.test", "/api/v4/users/user.test/status", %{},
     %{"availability" => "busy"}},
    {:self_preferences, %{}, "/api/v4/user/preferences", %{},
     %{"show_whitespace_in_diffs" => true}},
    {:self_counts, %{}, "/api/v4/user_counts", %{}, %{"assigned_issues" => 2}},
    {:user_counts, 123, "/api/v4/users/123/associations_count", %{}, %{"projects_count" => 3}},
    {:activities, %{}, "/api/v4/user/activities", %{}, [%{"username" => "user.test"}]},
    {:list_projects_and_groups, %{id: 123, type: "Project"}, "/api/v4/users/123/memberships",
     %{"type" => "Project"}, [%{"source_id" => 6, "source_type" => "Project"}]}
  ]

  for {action, params, path, query, response} <- @get_requests do
    test "#{action} requests the expected endpoint and decodes the response" do
      response = unquote(Macro.escape(response))
      client_stub({:ok, 200, Jason.encode!(response), []})

      params = unquote(Macro.escape(params))
      assert {:ok, ^response} = apply(GitlabApi.Users, unquote(action), [params])

      assert_request(:get, unquote(path), unquote(Macro.escape(query)))
    end
  end

  test "list casts string keys and preserves false filters" do
    client_stub({:ok, 200, "[]", []})

    params = %{
      "username" => "user.test",
      "active" => "true",
      "external" => false,
      "sort" => :asc,
      "unknown" => "discarded"
    }

    assert GitlabApi.Users.list(params) == {:ok, []}

    assert_request(:get, "/api/v4/users", %{
      "username" => "user.test",
      "active" => "true",
      "external" => "false",
      "sort" => "asc"
    })
  end

  test "list serializes ISO datetime filters" do
    client_stub({:ok, 200, "[]", []})

    params = %{
      created_after: "2026-11-01T12:30:00+03:00",
      created_before: ~U[2026-11-06 12:30:00Z]
    }

    assert GitlabApi.Users.list(params) == {:ok, []}

    assert_request(:get, "/api/v4/users", %{
      "created_after" => "2026-11-01T12:30:00+03:00",
      "created_before" => "2026-11-06T12:30:00Z"
    })
  end

  test "create sends required fields without requiring location" do
    response = %{"id" => 123, "username" => "user.test"}
    client_stub({:ok, 201, Jason.encode!(response), []})

    params = %{
      username: "user.test",
      name: "User Test",
      email: "user@example.com",
      reset_password: true
    }

    assert GitlabApi.Users.create(params) == {:ok, response}

    assert_request(:post, "/api/v4/users", %{
      "username" => "user.test",
      "name" => "User Test",
      "email" => "user@example.com",
      "reset_password" => true
    })
  end

  test "update removes the ID from the JSON body and keeps false values" do
    response = %{"id" => 123, "name" => "New Name"}
    client_stub({:ok, 200, Jason.encode!(response), []})

    assert GitlabApi.Users.update(%{id: "123", name: "New Name", external: false}) ==
             {:ok, response}

    assert_request(:put, "/api/v4/users/123", %{"name" => "New Name", "external" => false})
  end

  test "delete sends hard_delete in the query and handles an empty response" do
    client_stub({:ok, 204, "", []})

    assert GitlabApi.Users.delete(%{id: 123, hard_delete: false}) == {:ok, ""}
    assert_request(:delete, "/api/v4/users/123", %{"hard_delete" => "false"})
  end

  test "set_self_status sends JSON status settings" do
    response = %{"message" => "Reviewing code", "availability" => "busy"}
    client_stub({:ok, 200, Jason.encode!(response), []})

    params = %{
      emoji: "books",
      message: "Reviewing code",
      availability: "busy",
      clear_status_after: "1_day"
    }

    assert GitlabApi.Users.set_self_status(params) == {:ok, response}

    assert_request(:put, "/api/v4/user/status", %{
      "emoji" => "books",
      "message" => "Reviewing code",
      "availability" => "busy",
      "clear_status_after" => "1_day"
    })
  end

  test "update_self_preferences sends false settings" do
    params = %{
      view_diffs_file_by_file: false,
      show_whitespace_in_diffs: true,
      pass_user_identities_to_ci_jwt: false
    }

    response = %{
      "view_diffs_file_by_file" => false,
      "show_whitespace_in_diffs" => true,
      "pass_user_identities_to_ci_jwt" => false
    }

    client_stub({:ok, 200, Jason.encode!(response), []})

    assert GitlabApi.Users.update_self_preferences(params) == {:ok, response}
    assert_request(:put, "/api/v4/user/preferences", response)
  end

  test "activities serializes a datetime" do
    client_stub({:ok, 200, "[]", []})

    assert GitlabApi.Users.activities(%{from: ~N[2026-11-01 12:30:00]}) == {:ok, []}
    assert_request(:get, "/api/v4/user/activities", %{"from" => "2026-11-01T12:30:00"})
  end

  test "rejects missing fields without sending a request" do
    assert GitlabApi.Users.create(%{}) ==
             {:error, %{username: :missing, name: :missing, email: :missing}}

    assert GitlabApi.Users.update(%{name: "New Name"}) == {:error, %{id: :missing}}
  end

  test "rejects invalid IDs, datetimes and status values" do
    assert GitlabApi.Users.get("invalid") == {:error, {:primitive_type_error, "invalid"}}

    assert GitlabApi.Users.list(%{created_after: "invalid"}) ==
             {:error, %{created_after: :invalid}}

    assert {:error, %{availability: _}} =
             GitlabApi.Users.set_self_status(%{availability: "unknown"})
  end
end
