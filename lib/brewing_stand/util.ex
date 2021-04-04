defmodule BrewingStand.Util do
  # @type packet :: list(byte())
  @type short :: -32768..32767
  @type sbyte :: -128..127

  @type length_error :: {:error, :too_short}

  @spec next_string(binary()) ::
          {:ok, String.t(), binary()} | length_error()
  def next_string(data) when is_binary(data) do
    if byte_size(data) >= 64 do
      <<str::binary-size(64), rest::binary>> = data
      str = str |> :unicode.characters_to_binary() |> String.trim_trailing()

      {:ok, str, rest}
    else
      {:error, :too_short}
    end
  end

  @spec next_short(binary()) :: {:ok, short(), binary()} | length_error()
  def next_short(data) when is_binary(data) do
    if byte_size(data) >= 2 do
      <<short::size(16)-signed, rest::binary>> = data
      {:ok, short, rest}
    else
      {:error, :too_short}
    end
  end

  def next_sbyte(data) when is_binary(data) do
    <<sbyte::size(8)-signed, rest::binary>> = data
    {:ok, sbyte, rest}
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

  @spec pad_string(binary()) :: binary()
  def pad_string(str) when is_binary(str), do: pad_binary(str, 64, " ")

  @spec pad_byte_array(binary()) :: binary()
  def pad_byte_array(data) when is_binary(data), do: pad_binary(data, 1024, <<0>>)

  def pad_binary(binary, size, _el)
      when is_binary(binary) and is_integer(size) and size > 0 and byte_size(binary) >= size,
      do: binary

  def pad_binary(binary, size, el)
      when is_binary(binary) and is_integer(size) and size > 0 do
    pad_size = size - byte_size(binary)
    pad = :binary.copy(el, pad_size)

    binary <> pad
  end

  def chunk_binary(binary, count), do: chunk_binary(binary, count, [])

  def chunk_binary(binary, count, acc) when byte_size(binary) <= count,
    do: Enum.reverse([binary | acc])

  def chunk_binary(binary, count, acc) do
    chunk_size = count * 8
    <<chunk::size(chunk_size), rest::binary>> = binary

    chunk_binary(rest, count, [<<chunk::size(chunk_size)>> | acc])
  end

  @spec to_short(short()) :: binary()
  def to_short(int) when is_integer(int) and int >= -32768 and int <= 32767 do
    <<int::size(16)-signed>>
  end

  @spec to_sbyte(sbyte) :: byte()
  def to_sbyte(int) when is_integer(int) and int >= -128 and int <= 127 do
    <<sbyte>> = <<int::size(8)-signed>>
    sbyte
  end

  @spec to_fp_short(float() | integer()) :: binary()
  def to_fp_short(num) do
    # MC fixed point numbers have 5 points, multiplying by 32 achieves that, and
    # then truncate any other point.
    num = (num * 32) |> trunc()
    to_short(num)
  end
end
