defmodule ExAws.Dynamo.DecoderTest do
  use ExUnit.Case, async: true
  alias ExAws.Dynamo.Decoder
  alias ExAws.Dynamo.Encoder

  test "Decode boolean (boolean and string boolean)" do
    assert Decoder.decode(%{"BOOL" => true}) == true
    assert Decoder.decode(%{"BOOL" => "false"}) == false
  end

  test "Decode string" do
    assert Decoder.decode(%{"S" => "foo"}) == "foo"
  end

  test "Decode map (different types)" do
    assert %{"M" => %{foo: %{"S" => "bar"}, bar: %{"N" => 23}}}
           |> Decoder.decode() == %{foo: "bar", bar: 23}
  end

  test "Decode map whose attribute names collide with Dynamo type descriptors" do
    # The contents of an M value are always attribute name => AttributeValue, even when an
    # attribute happens to be named like a type descriptor.
    assert Decoder.decode(%{"M" => %{"S" => %{"N" => "1"}, "other" => %{"S" => "x"}}}) ==
             %{"S" => 1, "other" => "x"}

    assert Decoder.decode(%{"M" => %{"L" => %{"S" => "x"}}}) == %{"L" => "x"}
    assert Decoder.decode(%{"M" => %{"M" => %{"S" => %{"S" => "x"}}}}) == %{"M" => %{"S" => "x"}}
    assert Decoder.decode(%{"M" => %{"NULL" => %{"BOOL" => false}}}) == %{"NULL" => false}
    assert Decoder.decode(%{"M" => %{"N" => %{"S" => "evil"}}}) == %{"N" => "evil"}
  end

  test "Decode item with attributes named like Dynamo type descriptors" do
    item = %{"S" => %{"S" => "foo"}, "N" => %{"N" => "1"}, "L" => %{"L" => []}, "id" => %{"S" => "1"}}
    assert Decoder.decode(item) == %{"S" => "foo", "N" => 1, "L" => [], "id" => "1"}
  end

  test "Encoding then decoding a map shaped like a Dynamo value round-trips" do
    values = [
      %{"N" => "1000000"},
      %{"S" => "evil"},
      %{"NULL" => "true"},
      %{"L" => "x"},
      %{"BOOL" => true},
      %{"B" => "AAEC"},
      %{"M" => %{"role" => %{"S" => "admin"}, "is_admin" => %{"BOOL" => true}}}
    ]

    for value <- values do
      assert value |> Encoder.encode() |> Decoder.decode() == value
      assert %{"v" => value} |> Encoder.encode_root() |> Decoder.decode() == %{"v" => value}
    end
  end

  test "Decode number set to a mapset of numbers" do
    assert %{"NS" => ["1", "2", "3"]}
           |> Decoder.decode() == MapSet.new([1, 2, 3])

    assert %{"NS" => [1, 2, 3]}
           |> Decoder.decode() == MapSet.new([1, 2, 3])
  end

  test "Decode string set to a mapset of strings" do
    assert %{"SS" => ["foo", "bar", "baz"]}
           |> Decoder.decode() == MapSet.new(["foo", "bar", "baz"])
  end

  test "Decode binary set to a mapset of strings" do
    assert %{"BS" => ["U3Vubnk=", "UmFpbnk=", "U25vd3k="]}
           |> Decoder.decode() == MapSet.new(["U3Vubnk=", "UmFpbnk=", "U25vd3k="])
  end

  test "Decode lists (different types)" do
    assert %{"L" => [%{"S" => "asdf"}, %{"N" => "1"}]}
           |> Decoder.decode() == ["asdf", 1]
  end

  test "Decoder integers" do
    assert Decoder.decode(%{"N" => "23"}) == 23
    assert Decoder.decode(%{"N" => 23}) == 23
  end

  test "Decode floats" do
    assert Decoder.decode(%{"N" => "23.1"}) == 23.1
    assert Decoder.decode(%{"N" => 23.1}) == 23.1
  end

  test "Decode null" do
    assert Decoder.decode(%{"NULL" => "true"}) == nil
    assert Decoder.decode(%{"NULL" => true}) == nil
  end

  test "Decode structs" do
    user = %Test.User{email: "foo@bar.com", name: "Bob", age: 23, admin: false}
    assert user == user |> Encoder.encode() |> Decoder.decode(as: Test.User)
  end

  test "Decode non-string binaries" do
    assert :zlib.unzip(
             Decoder.decode(%{
               "B" => "BcGBCQAgCATAVX6ZBvlKUogP1P3pbmi9bYlFwal9DTPEDCu0s8E06DWqM3TqAw=="
             })
           ) == "Encoder can handle binaries that are not strings"
  end
end
