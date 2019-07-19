defmodule ExAws.DynamoTest do
  use ExUnit.Case, async: true
  alias ExAws.Dynamo

  ## NOTE:
  # These tests are not intended to be operational examples, but intead mere
  # ensure that the form of the data to be sent to AWS is correct.
  #

  test "#create_table with default opts" do
    expected = %{
      "AttributeDefinitions" => [
        %{"AttributeName" => :email, "AttributeType" => "S"},
        %{"AttributeName" => :age, "AttributeType" => "N"}
      ],
      "KeySchema" => [
        %{"AttributeName" => :email, "KeyType" => "HASH"},
        %{"AttributeName" => :age, "KeyType" => "RANGE"}
      ],
      "ProvisionedThroughput" => %{"ReadCapacityUnits" => 1, "WriteCapacityUnits" => 1},
      "TableName" => "Users",
      "BillingMode" => "PROVISIONED"
    }

    assert Dynamo.create_table(
             "Users",
             [email: :hash, age: :range],
             [email: :string, age: :number],
             1,
             1
           ).data == expected
  end

  test "#create_table with specified opts" do
    expected = %{
      "AttributeDefinitions" => [
        %{"AttributeName" => :email, "AttributeType" => "S"},
        %{"AttributeName" => :age, "AttributeType" => "N"}
      ],
      "KeySchema" => [
        %{"AttributeName" => :email, "KeyType" => "HASH"},
        %{"AttributeName" => :age, "KeyType" => "RANGE"}
      ],
      "TableName" => "Users",
      "BillingMode" => "PAY_PER_REQUEST"
    }

    assert Dynamo.create_table(
             "Users",
             [email: :hash, age: :range],
             [email: :string, age: :number],
             nil,
             nil,
             :pay_per_request
           ).data == expected
  end

  test "create_table with secondary indexes and default opts" do
    expected = %{
      "AttributeDefinitions" => [%{"AttributeName" => :id, "AttributeType" => "S"}],
      "GlobalSecondaryIndexes" => [
        %{
          "IndexName" => "my-global-index",
          "KeySchema" => [%{"AttributeName" => "email", "AttributeType" => "string"}]
        }
      ],
      "KeySchema" => [%{"AttributeName" => :id, "KeyType" => "HASH"}],
      "LocalSecondaryIndexes" => [
        %{
          "IndexName" => "my-global-index",
          "KeySchema" => [%{"AttributeName" => "email", "AttributeType" => "string"}]
        }
      ],
      "ProvisionedThroughput" => %{"ReadCapacityUnits" => 1, "WriteCapacityUnits" => 1},
      "TableName" => "TestUsers",
      "BillingMode" => "PROVISIONED"
    }

    secondary_index = [
      %{
        index_name: "my-global-index",
        key_schema: [
          %{
            attribute_name: "email",
            attribute_type: "string"
          }
        ]
      }
    ]

    assert Dynamo.create_table(
             "TestUsers",
             [id: :hash],
             %{id: :string},
             1,
             1,
             secondary_index,
             secondary_index
           ).data == expected
  end

  test "#update_table" do
    expected = %{"BillingMode" => "PAY_PER_REQUEST", "TableName" => "TestUsers"}

    assert Dynamo.update_table(
             "TestUsers",
             [billing_mode: :pay_per_request]
           ).data == expected

    expected = %{
      "BillingMode" => "PROVISIONED",
      "ProvisionedThroughput" => %{
        "ReadCapacityUnits" => 1,
        "WriteCapacityUnits" => 1
      },
      "TableName" => "TestUsers"
    }

    assert Dynamo.update_table(
             "TestUsers",
             [provisioned_throughput:
               [read_capacity_units: 1,
                write_capacity_units: 1],
              billing_mode: :provisioned
             ]).data == expected

    expected = %{
      "ProvisionedThroughput" => %{
        "ReadCapacityUnits" => 2,
        "WriteCapacityUnits" => 3
      },
      "TableName" => "TestUsers"
    }

    assert Dynamo.update_table(
             "TestUsers",
             [provisioned_throughput:
               [read_capacity_units: 2,
                write_capacity_units: 3]
             ]).data == expected
  end

  test "#scan" do
    expected = %{
      "ExclusiveStartKey" => %{api_key: %{"S" => "api_key"}},
      "ExpressionAttributeNames" => %{api_key: "#api_key"},
      "ExpressionAttributeValues" => %{
        ":api_key" => %{"S" => "asdfasdfasdf"},
        ":name" => %{"S" => "bubba"}
      },
      "FilterExpression" => "ApiKey = #api_key and Name = :name",
      "Limit" => 12,
      "TableName" => "Users"
    }

    assert Dynamo.scan(
             "Users",
             limit: 12,
             exclusive_start_key: [api_key: "api_key"],
             expression_attribute_names: [api_key: "#api_key"],
             expression_attribute_values: [api_key: "asdfasdfasdf", name: "bubba"],
             filter_expression: "ApiKey = #api_key and Name = :name"
           ).data == expected
  end

  test "#query" do
    expected = %{
      "ExclusiveStartKey" => %{api_key: %{"S" => "api_key"}},
      "ExpressionAttributeNames" => %{api_key: "#api_key"},
      "ExpressionAttributeValues" => %{
        ":api_key" => %{"S" => "asdfasdfasdf"},
        ":name" => %{"S" => "bubba"}
      },
      "FilterExpression" => "ApiKey = #api_key and Name = :name",
      "Limit" => 12,
      "TableName" => "Users"
    }

    assert Dynamo.query(
             "Users",
             limit: 12,
             exclusive_start_key: [api_key: "api_key"],
             expression_attribute_names: [api_key: "#api_key"],
             expression_attribute_values: [api_key: "asdfasdfasdf", name: "bubba"],
             filter_expression: "ApiKey = #api_key and Name = :name"
           ).data == expected
  end

  test "#batch_get_item" do
    expected = %{
      "RequestItems" => %{
        "Subscriptions" => %{"Keys" => [%{id: %{"S" => "id1"}}]},
        "Users" => %{
          "ConsistentRead" => true,
          "Keys" => [%{api_key: %{"S" => "key1"}}, %{api_key: %{"S" => "api_key2"}}]
        }
      }
    }

    request =
      Dynamo.batch_get_item(%{
        "Users" => [
          consistent_read: true,
          keys: [
            [api_key: "key1"],
            [api_key: "api_key2"]
          ]
        ],
        "Subscriptions" => %{keys: [%{id: "id1"}]}
      }).data

    assert request == expected
  end

  test "#batch_write_item" do
    expected = %{
      "RequestItems" => %{
        "Users" => [
          %{"DeleteRequest" => %{"Key" => %{"api_key" => %{"S" => "api_key1"}}}},
          %{
            "PutRequest" => %{
              "Item" => %{
                "admin" => %{"BOOL" => "false"},
                "age" => %{"N" => "23"},
                "email" => %{"S" => "foo@bar.com"},
                "name" => %{"M" => %{"first" => %{"S" => "bob"}, "last" => %{"S" => "bubba"}}}
              }
            }
          }
        ]
      }
    }

    user = %Test.User{
      email: "foo@bar.com",
      name: %{first: "bob", last: "bubba"},
      age: 23,
      admin: false
    }

    assert Dynamo.batch_write_item(%{
             "Users" => [
               [delete_request: [key: %{api_key: "api_key1"}]],
               [put_request: [item: user]]
             ]
           }).data == expected
  end

  test "put item" do
    expected = %{
      "Item" => %{
        "admin" => %{"BOOL" => "false"},
        "age" => %{"N" => "23"},
        "email" => %{"S" => "foo@bar.com"},
        "name" => %{"M" => %{"first" => %{"S" => "bob"}, "last" => %{"S" => "bubba"}}}
      },
      "TableName" => "Users"
    }

    user = %Test.User{
      email: "foo@bar.com",
      name: %{first: "bob", last: "bubba"},
      age: 23,
      admin: false
    }

    assert Dynamo.put_item("Users", user).data == expected
  end

  test "update_time_to_live" do
    expected = %{
      "TableName" => "Users",
      "TimeToLiveSpecification" => %{
        "AttributeName" => "expires_at",
        "Enabled" => true
      }
    }

    request = Dynamo.update_time_to_live("Users", "expires_at", true)

    assert Enum.at(request.headers, 0) == {"x-amz-target", "DynamoDB_20120810.UpdateTimeToLive"}
    assert request.data == expected
  end

  test "describe_time_to_live" do
    expected = %{
      "TableName" => "Users"
    }

    request = Dynamo.describe_time_to_live("Users")

    assert Enum.at(request.headers, 0) == {"x-amz-target", "DynamoDB_20120810.DescribeTimeToLive"}
    assert request.data == expected
  end
end
