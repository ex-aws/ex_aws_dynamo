defmodule ExAws.Dynamo.LazyTest do
  use ExUnit.Case, async: true
  alias ExAws.Dynamo

  # Fakes a two-page DynamoDB table: the first request returns one item plus a
  # LastEvaluatedKey, the follow-up request (which carries ExclusiveStartKey) returns the
  # last item. Every request body is sent back to the test process for inspection.
  defmodule FakeDynamo do
    @behaviour ExAws.Request.HttpClient

    @impl true
    def request(:post, _url, body, _headers, _opts) do
      request = Jason.decode!(body)
      send(self(), {:dynamo_request, request})

      response =
        case request do
          %{"ExclusiveStartKey" => _} ->
            %{"Items" => [%{"id" => %{"S" => "2"}}]}

          _ ->
            %{"Items" => [%{"id" => %{"S" => "1"}}], "LastEvaluatedKey" => %{"id" => %{"S" => "1"}}}
        end

      {:ok, %{status_code: 200, headers: [], body: Jason.encode!(response)}}
    end
  end

  @config [
    http_client: FakeDynamo,
    access_key_id: "AKIAFAKE",
    secret_access_key: "fake",
    region: "us-east-1"
  ]

  for operation <- [:scan, :query] do
    test "#{operation} stream passes LastEvaluatedKey back verbatim as ExclusiveStartKey" do
      items =
        apply(Dynamo, unquote(operation), ["Users", [limit: 1]])
        |> ExAws.stream!(@config)
        |> Enum.to_list()

      assert items == [%{"id" => %{"S" => "1"}}, %{"id" => %{"S" => "2"}}]

      assert_received {:dynamo_request, first}
      refute Map.has_key?(first, "ExclusiveStartKey")

      assert_received {:dynamo_request, second}
      assert second["ExclusiveStartKey"] == %{"id" => %{"S" => "1"}}
    end
  end
end
