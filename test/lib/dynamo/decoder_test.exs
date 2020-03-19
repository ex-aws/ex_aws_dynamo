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
    assert %{"M" => %{"M" => %{foo: %{"S" => "bar"}, bar: %{"N" => 23}}}}
           |> Decoder.decode() == %{foo: "bar", bar: 23}
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
