defmodule ExAws.Dynamo.EncodedTest do
  use ExUnit.Case, async: true
  alias ExAws.Dynamo.Encoded

  @valid [
    %{"S" => "foo"},
    %{"S" => ""},
    %{"N" => "1.5"},
    %{"B" => "dGVzdA=="},
    %{"BOOL" => false},
    %{"NULL" => true},
    %{"SS" => ["a", "b"]},
    %{"NS" => ["1", "2"]},
    %{"BS" => ["dGVzdA=="]},
    %{"L" => [%{"S" => "a"}, %{"N" => "1"}, %{"L" => []}]},
    %{"M" => %{"name" => %{"S" => "a"}, "nested" => %{"M" => %{"flag" => %{"BOOL" => true}}}}}
  ]

  @invalid [
    "foo",
    1,
    nil,
    [],
    %{},
    %{"S" => 1},
    %{"N" => 1},
    %{"B" => nil},
    %{"BOOL" => "true"},
    %{"NULL" => "true"},
    %{"X" => "foo"},
    %{"S" => "foo", "N" => "1"},
    %{"S" => "foo", "junk" => 1},
    %{"SS" => "a"},
    %{"NS" => [1]},
    %{"L" => %{}},
    %{"L" => ["a"]},
    %{"M" => %{"k" => "v"}},
    %{"M" => %{k: %{"S" => "v"}}},
    %{"M" => %{"k" => %{"S" => "v", "N" => "1"}}},
    %{"M" => MapSet.new()}
  ]

  test "new/1 accepts well-formed AttributeValues" do
    for value <- @valid do
      assert Encoded.valid?(value), "expected #{inspect(value)} to be valid"
      assert %Encoded{value: ^value} = Encoded.new(value)
    end
  end

  test "new/1 rejects anything that is not a well-formed AttributeValue" do
    for value <- @invalid do
      refute Encoded.valid?(value), "expected #{inspect(value)} to be invalid"
      assert_raise ArgumentError, ~r/expected a DynamoDB AttributeValue/, fn -> Encoded.new(value) end
    end
  end
end
