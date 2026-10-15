defmodule ExAws.Dynamo.Decoder do
  @moduledoc """
  Decodes a Dynamo response into a struct.

  If Dynamo.Decodable is implemented for the struct, it will be called
  after the completion of the coercion.

  This is important for handling nested maps if you wanted the nested maps
  to have atom keys.
  """

  alias ExAws.Dynamo.Decodable

  def decode(item, as: struct_module) do
    item
    |> decode
    |> binary_map_to_struct(struct_module)
    |> Decodable.decode()
  end

  @doc """
  Convert Dynamo format to Elixir

  Functions which convert the Dynamo-style values into normal Elixir values.
  Use these if you just want the Dynamo result to look more like Elixir without
  coercing it into a particular struct.

  Accepts either a single typed `AttributeValue` (such as `%{"S" => "foo"}`) or an item,
  i.e. a map of attribute name to `AttributeValue`. The typed clauses check the shape of
  the value, so an item with an attribute that happens to be named like a type descriptor
  (`"S"`, `"L"`, ...) is still decoded as an item.
  """
  def decode(%{"BOOL" => true}), do: true
  def decode(%{"BOOL" => false}), do: false
  def decode(%{"BOOL" => "true"}), do: true
  def decode(%{"BOOL" => "false"}), do: false
  def decode(%{"NULL" => true}), do: nil
  def decode(%{"NULL" => "true"}), do: nil
  def decode(%{"B" => value}) when is_binary(value), do: Base.decode64!(value)
  def decode(%{"S" => value}) when is_binary(value), do: value
  def decode(%{"M" => value}) when is_map(value), do: decode_item(value)

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

  # The contents of an `M` value, and a top-level item, are always a map of
  # attribute name => AttributeValue. Decode each attribute's value without first
  # trying to interpret the whole map as a typed value, so attributes named like a type
  # descriptor (e.g. an attribute called "S") are not mistaken for one.
  defp decode_item(item) do
    Enum.reduce(item, %{}, fn {k, v}, map ->
      Map.put(map, k, decode(v))
    end)
  end

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
