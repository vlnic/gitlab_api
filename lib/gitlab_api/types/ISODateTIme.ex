defmodule GitlabApi.Types.ISODateTIme do
  @behaviour Construct.Type

  def cast(%DateTime{} = dt) do
    {:ok, DateTime.to_iso8601(dt)}
  end

  def cast(%NaiveDateTime{} = dt) do
    {:ok, NaiveDateTime.to_iso8601(dt)}
  end

  def cast(dt) when is_binary(dt) do
    case DateTime.from_iso8601(dt) do
      {:ok, dt, _} -> dt
      _ -> :error
    end
  end
  def cast(_), do: :error
end
