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

  def try_connect do
    port = get_port()

    if is_nil(port) do
      {:error, "No value provided for :port in config/ddb_local_test.exs."}
    else
      case :gen_tcp.connect('localhost', port, []) do
        {:ok, _} -> :ok
        {:error, error} -> {:error, error}
      end
    end
  end

  def get_port, do: Application.get_env(:ex_aws, :dynamodb, [])[:port]
end
