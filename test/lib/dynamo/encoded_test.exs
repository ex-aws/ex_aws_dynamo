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

  test "new/1 requires N to be a decimal number string" do
    for n <- ["1", "-1", "1.5", "-0.25", "1.0e10", "1e-5", "+3", ".5", "123456789012345678901234567890"] do
      assert Encoded.valid?(%{"N" => n}), n
    end

    for n <- ["evil", "", "1,5", "0x10", " 1", "1 ", "NaN", "1e", "1e5.5", 1] do
      refute Encoded.valid?(%{"N" => n}), inspect(n)
    end

    assert_raise ArgumentError, fn -> Encoded.new(%{"N" => "evil"}) end
  end

  test "attributes/1 wraps every value of an attribute-name => AttributeValue map" do
    key = %{"pk" => %{"S" => "a"}, "sk" => %{"N" => "7"}}

    assert Encoded.attributes(key) == %{
             "pk" => %Encoded{value: %{"S" => "a"}},
             "sk" => %Encoded{value: %{"N" => "7"}}
           }

    assert Encoded.attributes(%{}) == %{}
    assert_raise ArgumentError, fn -> Encoded.attributes(%{"pk" => %{"S" => 1}}) end
    assert_raise ArgumentError, fn -> Encoded.attributes(%{"pk" => "a"}) end
  end
end
