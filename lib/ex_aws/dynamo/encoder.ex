defmodule ExAws.Dynamo.Encoder do
  @moduledoc """
  Takes an Elixir value and converts it into a Dynamo-style map.

  ```elixir
  MapSet.new [1,2,3] |> #{__MODULE__}.encode
  #=> %{"NS" => ["1", "2", "3"]}

  MapSet.new ["A","B","C"] |> #{__MODULE__}.encode
  #=> %{"SS" => ["A", "B", "C"]}

  "bubba" |> ExAws.Dynamo.Encoder.encode
  #=> %{"S" => "bubba"}
  ```

  This is handled via the ExAws.Dynamo.Encodable protocol.

  ## Values that are already in DynamoDB format

  The encoder never inspects the *shape* of a map to decide whether it has already been
  encoded. A map such as `%{"S" => "foo"}` is an ordinary map with a key named `"S"` and is
  encoded as `%{"M" => %{"S" => %{"S" => "foo"}}}`. Deciding by shape would let any
  caller-controlled map, such as a decoded JSON body, smuggle a raw, caller-chosen
  `AttributeValue` onto the wire.

  To pass a value that is already in DynamoDB format, mark it explicitly with
  `ExAws.Dynamo.Encoded.new/1`:

  ```elixir
  ExAws.Dynamo.Encoded.new(%{"B" => "dGVzdA=="}) |> ExAws.Dynamo.Encoder.encode
  #=> %{"B" => "dGVzdA=="}
  ```
  """

  alias ExAws.Dynamo.Encodable

  @doc """
  Encodes `value` into a Dynamo-style map via the `ExAws.Dynamo.Encodable` protocol.

  Encoding is applied unconditionally. Wrap values that are already in DynamoDB format with
  `ExAws.Dynamo.Encoded.new/1` to have them passed through verbatim.
  """
  def encode(value, options \\ []), do: Encodable.encode(value, options)

  @doc false
  @deprecated "encode!/2 is now identical to encode/2; use encode/2 instead"
  def encode!(value, options \\ []), do: encode(value, options)

  def encode_root(value, options \\ []) do
    case Encodable.encode(value, options) do
      %{"M" => value} -> value
      %{"L" => value} -> value
    end
  end

  def atom_to_dynamo_type(:blob), do: "B"
  def atom_to_dynamo_type(:boolean), do: "BOOL"
  def atom_to_dynamo_type(:blob_set), do: "BS"
  def atom_to_dynamo_type(:list), do: "L"
  def atom_to_dynamo_type(:map), do: "M"
  def atom_to_dynamo_type(:number_set), do: "NS"
  def atom_to_dynamo_type(:null), do: "NULL"
  def atom_to_dynamo_type(:number), do: "N"
  def atom_to_dynamo_type(:string), do: "S"
  def atom_to_dynamo_type(:string_set), do: "SS"

  def atom_to_dynamo_type(value) do
    raise ArgumentError, "Unknown dynamo type for value: #{inspect(value)}"
  end
end
