defmodule ExAws.Dynamo.EncoderTest do
  use ExUnit.Case, async: true
  alias ExAws.Dynamo.Encoded
  alias ExAws.Dynamo.Encoder

  test "Encoder converts numbers to binaries" do
    assert Encoder.encode(34) == %{"N" => "34"}
  end

  test "Encoder can handle map values" do
    result = %{foo: 1, bar: %{baz: 2, zounds: "asdf"}} |> Encoder.encode()

    assert %{
             "M" => %{
               "bar" => %{"M" => %{"baz" => %{"N" => "2"}, "zounds" => %{"S" => "asdf"}}},
               "foo" => %{"N" => "1"}
             }
           } == result
  end

  test "Encoder can handle floats" do
    assert Encoder.encode(0.4) == %{"N" => "0.4"}
  end

  test "Encoder allows empty strings in a map" do
    assert Encoder.encode(%{"data" => "value", "nodata" => ""}) == %{
             "M" => %{
               "data" => %{"S" => "value"},
               "nodata" => %{"S" => ""}
             }
           }
  end

  test "Encoder can handle binaries that are not strings" do
    assert Encoder.encode(:zlib.zip("Encoder can handle binaries that are not strings")) == %{
             "B" => "BcGBCQAgCATAVX6ZBvlKUogP1P3pbmi9bYlFwal9DTPEDCu0s8E06DWqM3TqAw=="
           }
  end

  test "Encoder with structs works properly" do
    user = %Test.User{email: "foo@bar.com", name: "Bob", age: 23, admin: false}

    assert %{
             "admin" => %{"BOOL" => false},
             "age" => %{"N" => "23"},
             "email" => %{"S" => "foo@bar.com"},
             "name" => %{"S" => "Bob"}
           } = Encoder.encode_root(user)
  end

  test "encoder handles lists properly" do
    assert ["foo", "bar"] |> Encoder.encode() == %{"L" => [%{"S" => "foo"}, %{"S" => "bar"}]}
    assert [1, 2] |> Encoder.encode() == %{"L" => [%{"N" => "1"}, %{"N" => "2"}]}
    assert ["foo", 1] |> Encoder.encode() == %{"L" => [%{"S" => "foo"}, %{"N" => "1"}]}
  end

  test "encoder handles mapsets properly" do
    assert MapSet.new([1, 2, 3]) |> Encoder.encode() == %{"NS" => ["1", "2", "3"]}
    assert MapSet.new(["A", "B", "C"]) |> Encoder.encode() == %{"SS" => ["A", "B", "C"]}

    assert_raise RuntimeError, "Cannot determine a proper data type for an empty MapSet", fn ->
      MapSet.new([]) |> Encoder.encode()
    end

    assert_raise RuntimeError,
                 "All elements in a MapSet must be only numbers or only strings",
                 fn ->
                   MapSet.new([1, "A"]) |> Encoder.encode()
                 end
  end

  test "encoder does not treat maps that merely look like Dynamo values as already encoded" do
    # Deciding by shape would let caller-controlled data (e.g. a decoded JSON body) choose
    # the raw AttributeValue that is sent to DynamoDB. Such maps are ordinary maps.
    assert Encoder.encode(%{"N" => "evil"}) == %{"M" => %{"N" => %{"S" => "evil"}}}

    assert Encoder.encode(%{"S" => "x", "junk" => 1}) ==
             %{"M" => %{"S" => %{"S" => "x"}, "junk" => %{"N" => "1"}}}

    assert Encoder.encode(%{"NULL" => true}) == %{"M" => %{"NULL" => %{"BOOL" => true}}}

    assert Encoder.encode(%{"M" => %{"role" => %{"S" => "admin"}}}) ==
             %{"M" => %{"M" => %{"M" => %{"role" => %{"M" => %{"S" => %{"S" => "admin"}}}}}}}

    for key <- ~w(B BOOL BS L M N NS NULL S SS) do
      assert %{"M" => %{^key => %{"S" => "payload"}}} = Encoder.encode(%{key => "payload"})
    end

    # Consequently encoding is not idempotent: encoding an encoded value wraps it in a Map.
    assert Encoder.encode(Encoder.encode(1)) == %{"M" => %{"N" => %{"S" => "1"}}}
  end

  test "encoder passes through values explicitly marked as already encoded" do
    raw = %{"B" => "dGVzdA=="}

    assert Encoder.encode(Encoded.new(raw)) == raw
    assert Encoder.encode(%{"blob" => Encoded.new(raw)}) == %{"M" => %{"blob" => raw}}
    assert Encoder.encode([Encoded.new(raw), 1]) == %{"L" => [raw, %{"N" => "1"}]}
    assert Encoder.encode_root(%{"blob" => Encoded.new(raw)}) == %{"blob" => raw}

    item = %{"M" => %{"id" => %{"S" => "1"}, "n" => %{"N" => "2"}}}
    assert Encoder.encode(Encoded.new(item)) == item
    assert Encoder.encode_root(Encoded.new(item)) == item["M"]
  end

  test "encoder works with nested structs" do
    nested_structs =
      %Test.Nested{items: [%Test.Nested{items: ["asdf"], secret: "foo"}], secret: "bar"}
      |> Encoder.encode_root()

    expected = %{"items" => %{"L" => [%{"M" => %{"items" => %{"L" => [%{"S" => "asdf"}]}}}]}}
    assert nested_structs == expected
  end

  test "encoder nil works" do
    assert Encoder.encode(nil) == %{"NULL" => true}
    assert Encoder.encode(%{"key" => nil}) == %{"M" => %{"key" => %{"NULL" => true}}}
  end

  test "encoder skips struct fields that are marked as excepted" do
    user_except =
      %Test.ExceptUser{email: "foo@bar.com", name: "Bob", age: 23, secret: "secret information"}
      |> Encoder.encode_root()

    assert %{
             "age" => %{"M" => %{"N" => %{"S" => "23"}}},
             "email" => %{"M" => %{"S" => %{"S" => "foo@bar.com"}}},
             "name" => %{"M" => %{"S" => %{"S" => "Bob"}}}
           } == Encoder.encode_root(user_except)
  end
end
