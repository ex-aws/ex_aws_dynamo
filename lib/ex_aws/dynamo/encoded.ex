defmodule ExAws.Dynamo.Encoded do
  @moduledoc """
  Marks a value as already being in DynamoDB wire format.

  `ExAws.Dynamo.Encoder` encodes every value it is given, including maps that happen to
  look like DynamoDB `AttributeValue`s such as `%{"S" => "foo"}` or `%{"N" => "1"}`. Those
  are encoded as ordinary maps (`%{"M" => %{"S" => %{"S" => "foo"}}}`). Wrap a value in
  this struct to have the encoder pass it through untouched instead, for example to force
  a specific DynamoDB type:

  ```elixir
  ExAws.Dynamo.scan("Users",
    expression_attribute_values: [api_key: ExAws.Dynamo.Encoded.new(%{"B" => "dGVzdA=="})]
  )
  ```

  The wrapper works anywhere an encodable value is accepted: in `expression_attribute_values`,
  as an item attribute, nested inside maps and lists, and as the item itself (as `%{"M" => ...}`).

  `new/1` validates that the value is a well-formed `AttributeValue`: a single-key map whose
  key is one of the ten DynamoDB type descriptors and whose value has the shape that type
  requires, recursively for `M` and `L`. It raises `ArgumentError` otherwise.

  Never wrap untrusted input. The whole point of the wrapper is that the wrapped value is
  sent to DynamoDB exactly as given, so whoever builds it chooses the stored type.
  """

  @enforce_keys [:value]
  defstruct [:value]

  @type t :: %__MODULE__{value: map()}

  @doc """
  Wraps `value`, which must be a well-formed DynamoDB `AttributeValue`.

  Raises `ArgumentError` if it is not.
  """
  @spec new(map()) :: t()
  def new(value) do
    if valid?(value) do
      %__MODULE__{value: value}
    else
      raise ArgumentError,
            "expected a DynamoDB AttributeValue (a single-key map such as " <>
              "%{\"S\" => \"foo\"} or %{\"N\" => \"1\"}), got: #{inspect(value)}"
    end
  end

  @doc """
  Returns `true` if `value` is a well-formed DynamoDB `AttributeValue`.
  """
  @spec valid?(term()) :: boolean()
  def valid?(%{"S" => value} = map) when map_size(map) == 1, do: is_binary(value)
  def valid?(%{"N" => value} = map) when map_size(map) == 1, do: is_binary(value)
  def valid?(%{"B" => value} = map) when map_size(map) == 1, do: is_binary(value)
  def valid?(%{"BOOL" => value} = map) when map_size(map) == 1, do: is_boolean(value)
  def valid?(%{"NULL" => value} = map) when map_size(map) == 1, do: value == true
  def valid?(%{"SS" => values} = map) when map_size(map) == 1, do: list_of_binaries?(values)
  def valid?(%{"NS" => values} = map) when map_size(map) == 1, do: list_of_binaries?(values)
  def valid?(%{"BS" => values} = map) when map_size(map) == 1, do: list_of_binaries?(values)

  def valid?(%{"L" => values} = map) when map_size(map) == 1 do
    is_list(values) and Enum.all?(values, &valid?/1)
  end

  def valid?(%{"M" => attributes} = map) when map_size(map) == 1 do
    is_map(attributes) and not is_struct(attributes) and
      Enum.all?(attributes, fn {name, value} -> is_binary(name) and valid?(value) end)
  end

  def valid?(_), do: false

  defp list_of_binaries?(values), do: is_list(values) and Enum.all?(values, &is_binary/1)
end

defimpl ExAws.Dynamo.Encodable, for: ExAws.Dynamo.Encoded do
  def encode(%ExAws.Dynamo.Encoded{value: value}, _options), do: value
end
