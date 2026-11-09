defmodule ExAws.DynamoTest do
  use ExUnit.Case, async: true
  alias ExAws.Dynamo

  ## NOTE:
  # These tests are not intended to be operational examples, but instead mere
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

  test "create_table with stream config" do
    expected = %{
      "AttributeDefinitions" => [%{"AttributeName" => :id, "AttributeType" => "S"}],
      "BillingMode" => "PAY_PER_REQUEST",
      "KeySchema" => [%{"AttributeName" => :id, "KeyType" => "HASH"}],
      "StreamSpecification" => %{
        "StreamEnabled" => true,
        "StreamViewType" => "KEYS_ONLY"
      },
      "TableName" => "TestUsers"
    }

    assert Dynamo.create_table(
             "TestUsers",
             [id: :hash],
             %{id: :string},
             billing_mode: :pay_per_request,
             stream_enabled: true,
             stream_view_type: :keys_only
           ).data == expected
  end

  test "create_table with explicitly disabled stream config" do
    expected = %{
      "AttributeDefinitions" => [%{"AttributeName" => :id, "AttributeType" => "S"}],
      "BillingMode" => "PAY_PER_REQUEST",
      "KeySchema" => [%{"AttributeName" => :id, "KeyType" => "HASH"}],
      "StreamSpecification" => %{
        "StreamEnabled" => false
      },
      "TableName" => "TestUsers"
    }

    assert Dynamo.create_table(
             "TestUsers",
             [id: :hash],
             %{id: :string},
             billing_mode: :pay_per_request,
             stream_enabled: false
           ).data == expected
  end

  test "#update_table" do
    expected = %{"BillingMode" => "PAY_PER_REQUEST", "TableName" => "TestUsers"}

    assert Dynamo.update_table(
             "TestUsers",
             billing_mode: :pay_per_request
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
             %{provisioned_throughput: %{read_capacity_units: 1, write_capacity_units: 1}, billing_mode: :provisioned}
           ).data == expected

    expected = %{
      "ProvisionedThroughput" => %{
        "ReadCapacityUnits" => 2,
        "WriteCapacityUnits" => 3
      },
      "TableName" => "TestUsers"
    }

    assert Dynamo.update_table("TestUsers",
             provisioned_throughput: [read_capacity_units: 2, write_capacity_units: 3]
           ).data == expected

    expected = %{
      "TableName" => "TestUsers",
      "StreamSpecification" => %{
        "StreamEnabled" => true,
        "StreamViewType" => "KEYS_ONLY"
      }
    }

    assert Dynamo.update_table(
             "TestUsers",
             stream_enabled: true,
             stream_view_type: :keys_only
           ).data == expected
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

  test "#query encodes expression attribute values that merely look like Dynamo values" do
    # A user-controlled map containing a type-descriptor key must be encoded as a Map,
    # not sent to DynamoDB verbatim as an attacker-chosen AttributeValue.
    data =
      Dynamo.query("Products",
        key_condition_expression: "attr = :val",
        expression_attribute_values: [val: %{"N" => "evil"}]
      ).data

    assert data["ExpressionAttributeValues"] == %{":val" => %{"M" => %{"N" => %{"S" => "evil"}}}}
  end

  test "#query passes through explicitly pre-encoded expression attribute values" do
    data =
      Dynamo.query("Products",
        key_condition_expression: "attr = :val",
        expression_attribute_values: [val: Dynamo.Encoded.new(%{"B" => "dGVzdA=="})]
      ).data

    assert data["ExpressionAttributeValues"] == %{":val" => %{"B" => "dGVzdA=="}}
  end

  test "#batch_get_item" do
    expected = %{
      "RequestItems" => %{
        "Subscriptions" => %{"Keys" => [%{id: %{"S" => "id1"}}]},
        "Users" => %{
          "ConsistentRead" => true,
          "Keys" => [%{api_key: %{"S" => "key1"}}, %{api_key: %{"S" => "api_key2"}}],
          "ExpressionAttributeNames" => %{"#api_key" => "api_key", "#id" => "id"},
          "ProjectionExpression" => "#id, #api_key"
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
          ],
          expression_attribute_names: %{"#id" => "id", "#api_key" => "api_key"},
          projection_expression: "#id, #api_key"
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
                "admin" => %{"BOOL" => false},
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
        "admin" => %{"BOOL" => false},
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

  test "put item with opts" do
    expected = %{
      "Item" => %{
        "admin" => %{"BOOL" => false},
        "age" => %{"N" => "23"},
        "email" => %{"S" => "foo@bar.com"},
        "name" => %{"M" => %{"first" => %{"S" => "bob"}, "last" => %{"S" => "bubba"}}}
      },
      "TableName" => "Users",
      "ConditionExpression" => "email = :email",
      "ExpressionAttributeNames" => %{"#admin" => "admin"},
      "ExpressionAttributeValues" => %{":admin" => %{"BOOL" => true}},
      "ReturnConsumedCapacity" => "TOTAL",
      "ReturnItemCollectionMetrics" => "SIZE",
      "ReturnValues" => "ALL_OLD",
      "ReturnValuesOnConditionCheckFailure" => "ALL_OLD"
    }

    user = %Test.User{
      email: "foo@bar.com",
      name: %{first: "bob", last: "bubba"},
      age: 23,
      admin: false
    }

    opts = [
      condition_expression: "email = :email",
      expression_attribute_names: %{"#admin" => "admin"},
      expression_attribute_values: [admin: true],
      return_consumed_capacity: :total,
      return_item_collection_metrics: :size,
      return_values: :all_old,
      return_values_on_condition_check_failure: :all_old
    ]

    assert Dynamo.put_item("Users", user, opts).data == expected
  end

  test "update item with opts" do
    expected = %{
      "Key" => %{"email" => %{"S" => "foo@bar.com"}},
      "TableName" => "Users",
      "ConditionExpression" => "email = :email",
      "ExpressionAttributeNames" => %{"#admin" => "admin"},
      "ExpressionAttributeValues" => %{":admin" => %{"BOOL" => true}},
      "ReturnConsumedCapacity" => "TOTAL",
      "ReturnItemCollectionMetrics" => "SIZE",
      "ReturnValues" => "ALL_OLD",
      "ReturnValuesOnConditionCheckFailure" => "ALL_OLD",
      "UpdateExpression" => "SET admin = :admin"
    }

    opts = [
      condition_expression: "email = :email",
      expression_attribute_names: %{"#admin" => "admin"},
      expression_attribute_values: [admin: true],
      return_consumed_capacity: :total,
      return_item_collection_metrics: :size,
      return_values: :all_old,
      return_values_on_condition_check_failure: :all_old,
      update_expression: "SET admin = :admin"
    ]

    assert Dynamo.update_item("Users", [email: "foo@bar.com"], opts).data == expected
  end

  test "delete item with opts" do
    expected = %{
      "Key" => %{"email" => %{"S" => "foo@bar.com"}},
      "TableName" => "Users",
      "ConditionExpression" => "email = :email",
      "ExpressionAttributeNames" => %{"#admin" => "admin"},
      "ExpressionAttributeValues" => %{":admin" => %{"BOOL" => true}},
      "ReturnConsumedCapacity" => "TOTAL",
      "ReturnItemCollectionMetrics" => "SIZE",
      "ReturnValues" => "ALL_OLD",
      "ReturnValuesOnConditionCheckFailure" => "ALL_OLD"
    }

    opts = [
      condition_expression: "email = :email",
      expression_attribute_names: %{"#admin" => "admin"},
      expression_attribute_values: [admin: true],
      return_consumed_capacity: :total,
      return_item_collection_metrics: :size,
      return_values: :all_old,
      return_values_on_condition_check_failure: :all_old
    ]

    assert Dynamo.delete_item("Users", [email: "foo@bar.com"], opts).data == expected
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

  test "transact_get_items" do
    expected = %{
      "TransactItems" => [
        %{
          "Get" => %{
            "Key" => %{"email" => %{"S" => "foo@baz.com"}},
            "TableName" => "Users",
            "ProjectionExpression" => "email,age"
          }
        }
      ]
    }

    request =
      Dynamo.transact_get_items([
        {"Users", %{"email" => "foo@baz.com"}, projection_expression: "email,age"}
      ])

    assert Enum.at(request.headers, 0) == {"x-amz-target", "DynamoDB_20120810.TransactGetItems"}
    assert request.data == expected
  end

  test "transact_write_items" do
    expected = %{
      "TransactItems" => [
        %{
          "Update" => %{
            "ConditionExpression" => "Likes = :old_likes",
            "ExpressionAttributeValues" => %{
              ":likes" => %{"N" => "9"},
              ":old_likes" => %{"N" => "99"}
            },
            "Key" => %{"email" => %{"S" => "foo@baz.com"}},
            "TableName" => "Users",
            "UpdateExpression" => "set Likes = :likes"
          }
        }
      ]
    }

    request =
      Dynamo.transact_write_items(
        update:
          {"Users", %{"email" => "foo@baz.com"},
           update_expression: "set Likes = :likes",
           condition_expression: "Likes = :old_likes",
           expression_attribute_values: [likes: 9, old_likes: 99]}
      )

    assert Enum.at(request.headers, 0) == {"x-amz-target", "DynamoDB_20120810.TransactWriteItems"}
    assert request.data == expected
  end

  test "#scan and #query pass a wire-format exclusive_start_key through when wrapped" do
    key = %{"id" => %{"S" => "user-42"}, "ts" => %{"N" => "7"}}
    wrapped = ExAws.Dynamo.Encoded.attributes(key)

    assert Dynamo.scan("Users", exclusive_start_key: wrapped).data["ExclusiveStartKey"] == key
    assert Dynamo.query("Users", exclusive_start_key: wrapped).data["ExclusiveStartKey"] == key

    # Unwrapped, the key is caller data and is encoded like any other map.
    assert Dynamo.scan("Users", exclusive_start_key: key).data["ExclusiveStartKey"] ==
             %{"id" => %{"M" => %{"S" => %{"S" => "user-42"}}}, "ts" => %{"M" => %{"N" => %{"S" => "7"}}}}
  end

  test "#batch_get_item accepts wire-format keys wrapped with Encoded.attributes/1" do
    keys = [%{"id" => %{"S" => "1"}}, %{"id" => %{"S" => "2"}}]
    wrapped = Enum.map(keys, &ExAws.Dynamo.Encoded.attributes/1)

    assert Dynamo.batch_get_item(%{"Users" => [keys: wrapped]}).data["RequestItems"]["Users"]["Keys"] ==
             keys
  end

  test "#decode_item works without options and with an attribute named M" do
    item = %{"M" => %{"S" => "x"}, "id" => %{"S" => "1"}}
    assert Dynamo.decode_item(item) == %{"M" => "x", "id" => "1"}
    assert Dynamo.decode_item(%{"Item" => item}) == %{"M" => "x", "id" => "1"}
    assert Dynamo.decode_item(%{"Items" => [item]}) == [%{"M" => "x", "id" => "1"}]
  end

  test "#decode_item unwraps a response once and keeps attributes named Item or Items" do
    with_s = %{"Item" => %{"S" => "x"}, "id" => %{"S" => "1"}}
    with_m = %{"Item" => %{"M" => %{"a" => %{"S" => "b"}}}, "id" => %{"S" => "1"}}
    with_l = %{"Items" => %{"L" => [%{"S" => "x"}]}, "id" => %{"S" => "1"}}

    cases = [
      {with_s, %{"Item" => "x", "id" => "1"}},
      {with_m, %{"Item" => %{"a" => "b"}, "id" => "1"}},
      {with_l, %{"Items" => ["x"], "id" => "1"}}
    ]

    for {item, decoded} <- cases do
      assert Dynamo.decode_item(item) == decoded
      assert Dynamo.decode_item(%{"Item" => item}) == decoded
      assert Dynamo.decode_item(%{"Items" => [item]}) == [decoded]
    end

    item = %{"Item" => %{"S" => "x"}, "name" => %{"S" => "n"}}
    assert Dynamo.decode_item(item, as: Test.User) == %Test.User{name: "n"}
    assert Dynamo.decode_item(%{"Item" => item}, as: Test.User) == %Test.User{name: "n"}
  end
end
