defmodule ExAws.Dynamo.Util do
  @moduledoc """
  A collection of light weight utility functions
  """

  @doc "Table exists"
  @spec table_exists?(table_name :: String.t) :: boolean
  def table_exists?(table_name) do
    try do
      ExAws.Dynamo.describe_table(table_name) |> ExAws.request!
      true
    rescue
      ExAws.Error -> false
    end
  end
end
