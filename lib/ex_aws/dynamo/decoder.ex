defmodule ExAws.Dynamo.Decoder do
  @moduledoc """
  Decodes a Dynamo response into a struct.

  If Dynamo.Decodable is implemented for the struct, it will be called
  after the completion of the coercion.

  This is important for handling nested maps if you wanted the nested maps
  to have atom keys.
  """

  alias ExAws.Dynamo.Decodable

  @doc """
  Decodes an item, i.e. a map of attribute name => `AttributeValue`, such as the `Item` of a
  `GetItem` response or an element of the `Items` of a `Query` or `Scan` response.

  Pass `as: StructModule` to coerce the result into that struct; `ExAws.Dynamo.Decodable`
  is applied to it afterwards.

  Use this rather than `decode/1` for items. Every `AttributeValue` is itself a map, so
  `decode/1` cannot tell an item whose attribute happens to be named `"M"` from an `M`
  value. Here every value is known to be an `AttributeValue`, so there is no ambiguity.
  """
  def decode_item(item, opts \\ [])

  def decode_item(item, as: struct_module) do
    item
    |> decode_item()
    |> binary_map_to_struct(struct_module)
    |> Decodable.decode()
  end

  def decode_item(item, []) when is_map(item) and not is_struct(item) do
    Enum.reduce(item, %{}, fn {k, v}, map ->
      Map.put(map, k, decode(v))
    end)
  end

  @doc """
  Decodes `value` with `decode/1` and coerces the result into `struct_module`.

  Unlike `decode_item/2` this accepts an `M` `AttributeValue` as well as an item, and so
  inherits the ambiguity of `decode/1` described below. Prefer `decode_item/2` for items.
  """
  def decode(value, as: struct_module) do
    value
    |> decode()
    |> binary_map_to_struct(struct_module)
    |> Decodable.decode()
  end

  @doc """
  Convert Dynamo format to Elixir

  Functions which convert the Dynamo-style values into normal Elixir values.
  Use these if you just want the Dynamo result to look more like Elixir without
  coercing it into a particular struct.

  Decodes a single typed `AttributeValue` such as `%{"S" => "foo"}`. For backwards
  compatibility a map that matches no typed clause is decoded as an item. The typed clauses
  check the value's shape so an item with an attribute named like a type descriptor is not
  mistaken for one; `M` additionally requires a single-key map, because its payload is a map
  like every `AttributeValue`. That still cannot tell an item whose *only* attribute is named
  `"M"` from an `M` value, so prefer `decode_item/1` for items.
  """
  def decode(%{"BOOL" => true}), do: true
  def decode(%{"BOOL" => false}), do: false
  def decode(%{"BOOL" => "true"}), do: true
  def decode(%{"BOOL" => "false"}), do: false
  def decode(%{"NULL" => true}), do: nil
  def decode(%{"NULL" => "true"}), do: nil
  def decode(%{"B" => value}) when is_binary(value), do: Base.decode64!(value)
  def decode(%{"S" => value}) when is_binary(value), do: value
  # Every AttributeValue is a map, so unlike the other typed clauses the shape of the payload
  # cannot tell an M value from an item that merely has an attribute named "M". A well-formed
  # AttributeValue has exactly one key, so require that here.
  def decode(%{"M" => value} = m) when map_size(m) == 1 and is_map(value), do: decode_item(value)

  def decode(%{"BS" => values}) when is_list(values), do: MapSet.new(values)
  def decode(%{"SS" => values}) when is_list(values), do: MapSet.new(values)

  def decode(%{"NS" => values}) when is_list(values) do
    values
    |> Stream.map(&binary_to_number/1)
    |> Enum.into(MapSet.new())
  end

  def decode(%{"L" => values}) when is_list(values) do
    Enum.map(values, &decode/1)
  end

  def decode(%{"N" => value}) when is_binary(value), do: binary_to_number(value)
  def decode(%{"N" => value}) when value |> is_integer or value |> is_float, do: value

  def decode(%{} = item), do: decode_item(item)

  @doc "Attempts to convert a number to a float, and then an integer"
  def binary_to_number(binary) when is_binary(binary) do
    String.to_float(binary)
  rescue
    ArgumentError -> String.to_integer(binary)
  end

  def binary_to_number(binary), do: binary

  @doc "Converts a map with binary keys to the specified struct"
  def binary_map_to_struct(bmap, module) do
    module.__struct__()
    |> Map.from_struct()
    |> Enum.reduce(%{}, fn {k, v}, map ->
      Map.put(map, k, Map.get(bmap, Atom.to_string(k), v))
    end)
    |> Map.put(:__struct__, module)
  end
end
