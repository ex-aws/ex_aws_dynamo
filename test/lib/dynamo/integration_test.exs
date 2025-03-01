defmodule ExAws.DynamoIntegrationTest do
  use ExUnit.Case, async: true

  ## These tests run against DynamoDB Local
  #
  # http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Tools.DynamoDBLocal.html
  # In this way they can safely delete data and tables without risking actual data on production Dynamo.

  # Only run the tests in this module if we can find a running
  # instance of DDB Local on the port specified in config/ddb_local_test.exs
  # See README for more information.
  case DDBLocal.try_connect() do
    :ok ->
      alias ExAws.Dynamo, warn: false

      setup_all do
        tables = [
          "TestUsers",
          Test.User,
          "TestSeveralUsers",
          TestFoo,
          "test_books",
          "TestUsersWithRange",
          "TestTransactions",
          "TestTransactions2",
          "TestStream",
          "TestUpdate"
        ]

        DDBLocal.delete_test_tables(tables)

        on_exit(fn ->
          DDBLocal.delete_test_tables(tables)
        end)
      end

      test "#list_tables" do
        assert {:ok, %{"TableNames" => _}} = Dynamo.list_tables() |> ExAws.request()
      end

      test "#create and destroy table" do
        assert {:ok, %{"TableDescription" => %{"TableName" => "Elixir.TestFoo"}}} =
                 Dynamo.create_table(TestFoo, :shard_id, [shard_id: :string], 1, 1) |> ExAws.request()
      end

      test "#create table with range" do
        assert {:ok, _} =
                 Dynamo.create_table(
                   "TestUsersWithRange",
                   [email: :hash, age: :range],
                   [email: :string, age: :number],
                   1,
                   1
                 )
                 |> ExAws.request()
      end

      test "#create table with stream" do
        assert {:ok, _} =
                 Dynamo.create_table(
                   "TestStream",
                   [email: :hash, age: :range],
                   [email: :string, age: :number],
                   billing_mode: :pay_per_request,
                   stream_enabled: true,
                   stream_view_type: :new_image
                 )
                 |> ExAws.request()
      end

      test "put and get item with map values work" do
        {:ok, _} = Dynamo.create_table(Test.User, :email, [email: :string], 1, 1) |> ExAws.request()

        user = %Test.User{
          email: "foo@bar.com",
          name: %{first: "bob", last: "bubba"},
          age: "",
          admin: false
        }

        assert {:ok, _} = Dynamo.put_item(Test.User, user) |> ExAws.request()

        item =
          Test.User
          |> Dynamo.get_item(%{email: user.email})
          |> ExAws.request!()
          |> Dynamo.decode_item(as: Test.User)

        assert user == item
      end

      test "put and get several items with map values work" do
        {:ok, _} = Dynamo.create_table("TestSeveralUsers", :email, [email: :string], 1, 1) |> ExAws.request()

        user1 = %Test.User{
          email: "foo@bar.com",
          name: %{first: "bob", last: "bubba"},
          age: 23,
          admin: false
        }

        user2 = %Test.User{
          email: "bar@bar.com",
          name: %{first: "jane", last: "bubba"},
          age: 21,
          admin: true
        }

        assert {:ok, _} = Dynamo.put_item("TestSeveralUsers", user1) |> ExAws.request()
        assert {:ok, _} = Dynamo.put_item("TestSeveralUsers", user2) |> ExAws.request()

        items =
          Dynamo.scan("TestSeveralUsers", limit: 2)
          |> ExAws.request!()
          |> Dynamo.decode_item(as: Test.User)

        assert Enum.at(items, 0) == user1
        assert Enum.at(items, 1) == user2
      end

      test "condition failure with return_values_on_condition_check_failure specified returns expected error" do
        user = %Test.User{
          email: "foo@bar.com",
          name: %{first: "bob", last: "bubba"},
          age: 25,
          admin: false
        }

        operations = [
          {"put_item", fn opts -> Dynamo.put_item(Test.User, user, opts) end},
          {"update_item", fn opts -> Dynamo.update_item(Test.User, [email: user.email], opts) end},
          {"delete_item", fn opts -> Dynamo.delete_item(Test.User, [email: user.email], opts) end}
        ]

        Enum.each(operations, fn {name, operation} ->
          DDBLocal.delete_test_tables([Test.User])

          {:ok, _} = Dynamo.create_table(Test.User, :email, [email: :string], 1, 1) |> ExAws.request()

          # When the condition failure return value is all_old but there is no old
          # item, the error is returned without an item
          assert {:error, {"ConditionalCheckFailedException", "The conditional request failed"}} =
                   operation.(
                     condition_expression: "email = :email",
                     expression_attribute_values: [email: "does-not-exist"],
                     return_values_on_condition_check_failure: :all_old
                   )
                   |> ExAws.request()

          {:ok, _} = Dynamo.put_item(Test.User, user) |> ExAws.request()

          # Ensure the default condition failure return value is none and thus no item is returned
          assert {:error, {"ConditionalCheckFailedException", "The conditional request failed"}} =
                   operation.(
                     condition_expression: "email = :email",
                     expression_attribute_values: [email: "does-not-exist"]
                   )
                   |> ExAws.request()

          # When the condition failure return value is none, no item is returned
          assert {:error, {"ConditionalCheckFailedException", "The conditional request failed"}} =
                   operation.(
                     condition_expression: "email = :email",
                     expression_attribute_values: [email: "does-not-exist"],
                     return_values_on_condition_check_failure: :none
                   )
                   |> ExAws.request(),
                 name

          # When the condition failure return value is all_old, the old item is returned
          assert {:error, {"ConditionalCheckFailedException", "The conditional request failed", user_item}} =
                   operation.(
                     condition_expression: "email = :email",
                     expression_attribute_values: [email: "does-not-exist"],
                     return_values_on_condition_check_failure: :all_old
                   )
                   |> ExAws.request()

          assert Dynamo.decode_item(user_item, as: Test.User) == user
        end)
      end

      test "transactions work" do
        {:ok, _} = Dynamo.create_table("TestTransactions", :email, [email: :string], 1, 1) |> ExAws.request()
        {:ok, _} = Dynamo.create_table("TestTransactions2", :email, [email: :string], 1, 1) |> ExAws.request()

        user1 = %Test.User{
          email: "foo@bar.com",
          name: %{first: "bob", last: "bubba"},
          age: 23,
          admin: false
        }

        assert {:ok, _} =
                 Dynamo.transact_write_items(put: {"TestTransactions", user1}, put: {"TestTransactions2", user1})
                 |> ExAws.request()

        user2 = %Test.User{
          email: "bar@bar.com",
          name: %{first: "jane", last: "bubba"},
          age: 21,
          admin: true
        }

        assert {:error, {"TransactionCanceledException", _, _}} =
                 Dynamo.transact_write_items(
                   put: {"TestTransactions", user2},
                   condition_check:
                     {"TestTransactions2", Map.take(user2, [:email]), condition_expression: "attribute_exists(age)"}
                 )
                 |> ExAws.request()

        assert {:ok, %{}} =
                 Dynamo.transact_write_items(
                   put: {"TestTransactions", user2},
                   put: {"TestTransactions2", user2},
                   update:
                     {"TestTransactions", Map.take(user1, [:email]),
                      update_expression: "set age = age + :one", expression_attribute_values: [one: 1]}
                 )
                 |> ExAws.request()

        assert {:ok, %{"Responses" => [get1, _get2]}} =
                 Dynamo.transact_get_items([
                   {"TestTransactions", Map.take(user1, [:email])},
                   {"TestTransactions2", Map.take(user2, [:email])}
                 ])
                 |> ExAws.request()

        assert 24 == get1 |> Dynamo.decode_item(as: Test.User) |> Map.get(:age)

        assert {:ok, %{}} =
                 Dynamo.transact_write_items(
                   delete: {"TestTransactions", Map.take(user1, [:email])},
                   delete: {"TestTransactions2", Map.take(user2, [:email])}
                 )
                 |> ExAws.request()

        assert {:ok, %{"Responses" => [%{}, %{}]}} =
                 Dynamo.transact_get_items([
                   {"TestTransactions", Map.take(user1, [:email])},
                   {"TestTransactions2", Map.take(user2, [:email])}
                 ])
                 |> ExAws.request()
      end

      test "stream scan" do
        {:ok, _} = Dynamo.create_table("TestUsers", :email, [email: :string], 1, 1) |> ExAws.request()

        user = %Test.User{
          email: "foo@bar.com",
          name: %{first: "bob", last: "bubba"},
          age: 23,
          admin: false
        }

        assert {:ok, _} = Dynamo.put_item("TestUsers", user) |> ExAws.request()

        user = %Test.User{
          email: "bar@bar.com",
          name: %{first: "bob", last: "bubba"},
          age: 23,
          admin: false
        }

        assert {:ok, _} = Dynamo.put_item("TestUsers", user) |> ExAws.request()

        user = %Test.User{
          email: "baz@bar.com",
          name: %{first: "bob", last: "bubba"},
          age: 23,
          admin: false
        }

        assert {:ok, _} = Dynamo.put_item("TestUsers", user) |> ExAws.request()

        assert Dynamo.scan("TestUsers", limit: 1)
               |> ExAws.stream!()
               |> Enum.count() == 3
      end

      test "batch_write_item works" do
        {:ok, _} =
          Dynamo.create_table(
            "test_books",
            [title: "hash", format: "range"],
            [title: :string, format: :string],
            1,
            1
          )
          |> ExAws.request()

        requests = [
          [put_request: [item: %{title: "Tale of Two Cities", format: "hardcover", price: 20.00}]],
          [put_request: [item: %{title: "Tale of Two Cities", format: "softcover", price: 10.00}]]
        ]

        assert {:ok, _} = Dynamo.batch_write_item(%{"test_books" => requests}) |> ExAws.request()

        delete_requests = [
          [delete_request: [key: %{title: "Tale of Two Cities", format: "hardcover"}]],
          [delete_request: [key: %{title: "Tale of Two Cities", format: "softcover"}]]
        ]

        assert {:ok, _} = Dynamo.batch_write_item(%{"test_books" => delete_requests}) |> ExAws.request()
      end

      test "update table" do
        assert {:ok, %{"TableDescription" => %{"TableName" => "TestUpdate"}}} =
                 Dynamo.create_table(
                   "TestUpdate",
                   [title: "hash", format: "range"],
                   title: :string,
                   format: :string
                 )
                 |> ExAws.request()

        assert {:ok,
                %{
                  "TableDescription" => %{
                    "StreamSpecification" => %{
                      "StreamEnabled" => true,
                      "StreamViewType" => "NEW_IMAGE"
                    },
                    "TableName" => "TestUpdate"
                  }
                }} =
                 Dynamo.update_table("TestUpdate", stream_enabled: true, stream_view_type: :new_image)
                 |> ExAws.request()
      end

    {:error, :econnrefused} ->
      IO.puts(
        "\nNo running local instance of DynamoDB found on port #{DDBLocal.get_port()}. Skipping tests in #{__MODULE__}..."
      )

    {:error, message} ->
      IO.puts("\n#{message} Skipping tests in #{__MODULE__}...")
  end
end
