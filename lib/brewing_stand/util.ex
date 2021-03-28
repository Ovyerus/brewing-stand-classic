defmodule BrewingStand.Util do
  @type packet :: list(byte())
  @type short :: -32768..32767

  @type length_error :: {:error, :too_short}

  @spec next_string(packet()) ::
          {:ok, String.t(), packet()} | length_error()
  @doc """
  Get next string in packet if possible. Also returns rest of packet as second
  item in tuple.
  """
  def next_string(data) when is_list(data) do
    if length(data) >= 64 do
      {str, rest} = Enum.split(data, 64)
      str = str |> to_string() |> String.trim_trailing()

      {:ok, str, rest}
    else
      {:error, :too_short}
    end
  end

  @spec next_short(packet()) :: {:ok, short(), packet()} | length_error()
  def next_short(data) when is_list(data) do
    if length(data) >= 2 do
      {short, rest} = Enum.split(data, 2)
      int = from_short(short)

      {:ok, int, rest}
    else
      {:error, :too_short}
    end
  end

  # TODO: probably need to split up larger chars into individual bytes, dunno
  @spec pad_string(charlist()) :: charlist()
  @doc """
  Pad a charlist to proper format for a packet.
  """
  def pad_string(str) when is_list(str), do: pad_list(str, 64, ' ')

  @spec pad_byte_array(packet()) :: packet()
  def pad_byte_array(data) when is_list(data), do: pad_list(data, 1024, 0x00)

  def pad_list(list, size, el), do: :string.pad(list, size, :trailing, el) |> List.flatten()

  @spec to_short(short()) :: list(byte())
  def to_short(int) when is_integer(int) and int > -32768 and int <= 32767 do
    # Split the int up into bit digits, and pad up to 15, so that we can prepend the sign
    bits = int |> abs() |> to_bits() |> :string.pad(15, :leading, 0) |> List.flatten()
    sign = if int < 0, do: 1, else: 0
    bits = [sign | bits]
    # Divide into bytes
    {first, second} = Enum.split(bits, 8)

    [from_bits(first), from_bits(second)]
  end

  def from_short([first, second]) do
    bits = to_bits(first) ++ to_bits(second)
    [sign | bits] = bits |> :string.pad(16, :leading, 0) |> List.flatten()
    bits = if sign == 1, do: Enum.map(bits, fn x -> x * -1 end), else: bits

    from_bits(bits)
  end

  defp to_bits(int), do: Integer.digits(int, 2)
  defp from_bits(bits), do: Integer.undigits(bits, 2)
end
