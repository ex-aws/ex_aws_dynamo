defmodule DDBLocal do
  @moduledoc """
  Helper methods for working with local DynamoDB during testing.
  """

  alias ExAws.Dynamo

  @doc """
  Delete tables created while running tests.
  """
  def delete_test_tables(tables) do
    tables
    |> Enum.each(fn table -> Dynamo.delete_table(table) |> ExAws.request() end)
    :ok
  end
end
