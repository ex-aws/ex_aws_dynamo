defmodule ExAws.Dynamo.DecoderTest do
  use ExUnit.Case, async: true
  alias ExAws.Dynamo.Decoder
  alias ExAws.Dynamo.Encoder

  if Application.get_env(:ex_aws, :dynamodb, [])[:decode_sets] do
    test "decoder decodes numberset to a mapset of numbers" do
      assert %{"NS" => ["1", "2", "3"]}
            |> Decoder.decode() == MapSet.new([1, 2, 3])

      assert %{"NS" => [1, 2, 3]}
            |> Decoder.decode() == MapSet.new([1, 2, 3])
    end

    test "decoder decodes stringset to a mapset of strings" do
      assert %{"SS" => ["foo", "bar", "baz"]}
        |> Decoder.decode() == MapSet.new(["foo", "bar", "baz"])
    end

    test "decoder decodes binaryset to a mapset of strings" do
      assert %{"BS" => ["U3Vubnk=", "UmFpbnk=", "U25vd3k="]}
        |> Decoder.decode() == MapSet.new(["U3Vubnk=", "UmFpbnk=", "U25vd3k="])
    end
  else
    test "decoder decodes numberset to a list of numbers" do
      assert %{"NS" => ["1", "2", "3"]}
            |> Decoder.decode() == [1, 2, 3]

      assert %{"NS" => [1, 2, 3]}
            |> Decoder.decode() == [1, 2, 3]
    end

    test "decoder decodes stringset to a list of strings" do
      assert %{"SS" => ["foo", "bar", "baz"]}
        |> Decoder.decode() == ["foo", "bar", "baz"]
    end

    test "decoder decodes binaryset to a list of strings" do
      assert %{"BS" => ["U3Vubnk=", "UmFpbnk=", "U25vd3k="]}
        |> Decoder.decode() == ["U3Vubnk=", "UmFpbnk=", "U25vd3k="]
    end
  end

  test "lists of different types" do
    assert %{"L" => [%{"S" => "asdf"}, %{"N" => "1"}]}
           |> Decoder.decode() == ["asdf", 1]
  end

  test "Decoder ints works" do
    assert Decoder.decode(%{"N" => "23"}) == 23
    assert Decoder.decode(%{"N" => 23}) == 23
  end

  test "Decoder floats works" do
    assert Decoder.decode(%{"N" => "23.1"}) == 23.1
    assert Decoder.decode(%{"N" => 23.1}) == 23.1
  end

  test "Decoder nil works" do
    assert Decoder.decode(%{"NULL" => "true"}) == nil
    assert Decoder.decode(%{"NULL" => true}) == nil
  end

  test "Decoder structs works properly" do
    user = %Test.User{email: "foo@bar.com", name: "Bob", age: 23, admin: false}
    assert user == user |> Encoder.encode() |> Decoder.decode(as: Test.User)
  end

  test "Decoder binary that are not strings works" do
    assert :zlib.unzip(
             Decoder.decode(%{
               "B" => "BcGBCQAgCATAVX6ZBvlKUogP1P3pbmi9bYlFwal9DTPEDCu0s8E06DWqM3TqAw=="
             })
           ) == "Encoder can handle binaries that are not strings"
  end
end
