defmodule BrewingStand.Util do
  @type packet :: list(byte())
  @type short :: -32768..32767
  @type sbyte :: -128..127

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

  def next_byte_array(data, chunk_size \\ 1024) when is_list(data) and chunk_size <= 1024 do
    if length(data) >= 1024 do
      {bytes, rest} = Enum.split(data, 1024)
      bytes = Enum.take(bytes, chunk_size)
      # Remove any padding the chunk may have
      # bytes = :string.trim(bytes, :trailing, [0])

      {:ok, bytes, rest}
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
  def to_short(int) when is_integer(int) and int >= -32768 and int <= 32767 do
    <<b1, b2>> = <<int::size(16)-signed>>
    [b1, b2]
  end

  @spec from_short(list(byte())) :: short()
  def from_short([first, second]) do
    <<short::size(16)-signed>> = <<first, second>>
    short
  end

  @spec to_sbyte(sbyte) :: byte()
  def to_sbyte(int) when is_integer(int) and int >= -128 and int <= 127 do
    <<sbyte>> = <<int::size(8)-signed>>
    sbyte
  end

  @spec from_sbyte(byte()) :: sbyte()
  def from_sbyte(sbyte) do
    <<int::size(8)-signed>> = <<sbyte>>
    int
  end

  @spec coords_to_player_position(short(), short(), short()) :: list(byte())
  def coords_to_player_position(x, y, z),
    # TODO
    do:
      [
        x |> point_to_player_coord() |> to_short(),
        y |> point_to_player_coord() |> Kernel.+(51) |> to_short(),
        z |> point_to_player_coord() |> to_short()
      ]
      |> List.flatten()
      |> IO.inspect()

  def point_to_player_coord(int), do: int * 32
end
