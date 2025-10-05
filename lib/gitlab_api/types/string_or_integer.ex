defmodule GitlabApi.Types.StringOrInteger do
  @behaviour Construct.Type

  def cast(type) when is_binary(type) or is_integer(type), do: {:ok, type}
  def cast(_), do: :error
end
