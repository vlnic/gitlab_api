defmodule GitlabApiTest do
  use ExUnit.Case
  doctest GitlabApi

  test "greets the world" do
    assert GitlabApi.hello() == :world
  end
end
