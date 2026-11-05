defmodule GitlabApi.Types.ISODate do
  @behaviour Construct.Type

  def cast(%Date{} = d) do
    {:ok, Date.to_iso8601(d)}
  end

  def cast(type) when is_binary(type) do
    case Date.from_iso8601(type) do
      {:ok, _} -> {:ok, type}
      _ -> :error
    end
  end

  def cast(_), do: :error
end
