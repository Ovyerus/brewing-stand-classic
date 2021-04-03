defmodule BrewingStand.DummyClient.PacketReader do
  require Logger

  alias BrewingStand.DummyClient.Level
  import BrewingStand.Util

  @op_codes %{
    # Identify (client & server)
    0x00 => 1 + 64 + 64 + 1,
    # Ping
    0x01 => 0,
    # Level initialize
    0x02 => 0,
    # Level data chunk
    0x03 => 2 + 1024 + 1,
    # Level finalize
    0x04 => 2 + 2 + 2 + 1,
    # Set block (server)
    0x06 => 2 + 2 + 2 + 1,
    # Spawn player
    0x07 => 1 + 64 + 2 + 2 + 2 + 1 + 1,
    # Player teleport
    0x08 => 1 + 2 + 2 + 2 + 1 + 1,
    # Player move
    0x09 => 1 + 1 + 1 + 1 + 1 + 1,
    # Player position
    0x0A => 1 + 1 + 1 + 1,
    # Player orientation
    0x0B => 1 + 1 + 1,
    # Despawn player
    0x0C => 1,
    # Message
    0x0D => 1 + 64,
    # Player dc
    0x0E => 64,
    # Update user type (op)
    0x0F => 1

    # Custom extensions
    # 0x10 => 64 + 2,
    # 0x11 => 64 + 4
  }

  def read(socket) do
    with {:ok, [op]} <- read_socket(socket, 1),
         {len, _} when len not in [0, nil] <- {@op_codes[op], op},
         {:ok, packet} <- read_socket(socket, len) do
      handle_packet(op, packet)
      read(socket)
    else
      {0, op} ->
        handle_packet(op, [])
        read(socket)

      {nil, op} ->
        Logger.warn("Unknown opcode #{op}")
        read(socket)

      {:stopped} ->
        nil

      {:error} ->
        read(socket)
    end
  end

  defp read_socket(socket, len) do
    case :gen_tcp.recv(socket, len) do
      {:ok, _} = r ->
        r

      {:error, :closed} ->
        System.stop(1)
        {:stopped}

      e ->
        Logger.error(inspect(e))
        {:error}
    end
  end

  def handle_packet(0x00, [protocol | data]) do
    case protocol do
      0x07 ->
        {:ok, name, data} = next_string(data)
        {:ok, motd, [op]} = next_string(data)

        Logger.info("Connected to #{name}\n#{motd}")
        Logger.debug(if op == 0x64, do: "I'm OP!", else: "I'm not OP")

      unk ->
        Logger.debug("Server gave unknown protocol #{unk}")
    end
  end

  def handle_packet(0x01, []), do: :ping
  def handle_packet(0x02, []), do: Logger.debug("Incoming level data")

  def handle_packet(0x03, data) do
    {:ok, chunk_len, data} = next_short(data)
    {:ok, chunk_data, data} = next_byte_array(data, chunk_len)
    [percentage] = data

    Level.add(chunk_data)
    Logger.debug("Received level chunk, size: #{chunk_len}, percentage: #{percentage}%")
  end

  def handle_packet(0x04, data) do
    {:ok, x, data} = next_short(data)
    {:ok, y, data} = next_short(data)
    {:ok, z, _} = next_short(data)

    Logger.debug("Level finalized, with world dimensions of #{x},#{y},#{z}")
    _world = Level.get_world()
  end

  def handle_packet(0x07, [player_id | data]) do
    IO.inspect([player_id | data])
    {:ok, username, data} = next_string(data)
    {:ok, x, data} = next_short(data)
    {:ok, y, data} = next_short(data)
    {:ok, z, [yaw, pitch]} = next_short(data)

    Logger.info("""
    Spawned into the world.
    Player ID: #{player_id}. Username: #{username}
    Coords: #{x},#{y},#{z}. Yaw: #{yaw}. Pitch: #{pitch}
    """)
  end

  def handle_packet(0x08, [player_id | data]) do
    IO.inspect([player_id | data])
    {:ok, x, data} = next_short(data)
    {:ok, y, data} = next_short(data)
    {:ok, z, [yaw, pitch]} = next_short(data)

    Logger.info("Teleported #{player_id}. Coords: #{x},#{y},#{z}. Yaw: #{yaw}. Pitch: #{pitch}")
  end

  def handle_packet(0x0D, [_unused | data]) do
    {:ok, message, []} = next_string(data)

    Logger.info("Got chat message\n#{message}")
  end

  # def handle_packet(0x10, data) do
  #   {:ok, app_name, data} = next_string(data)
  #   {:ok, ext_count, []} = next_short(data)

  #   Logger.debug("Server tried sending CPE extinfo packet, #{app_name} #{ext_count}")
  # end

  # def handle_packet(0x11, data) do
  #   {:ok, ext_name, [b1, b2, b3, b4]} = next_string(data)
  #   <<ver::size(32)>> = <<b1, b2, b3, b4>>

  #   Logger.debug("Server is really trying to negotiate CPE with us. #{ext_name} ver#{ver}")
  # end

  def handle_packet(op, pkt) do
    IO.inspect(op, label: "unhandled opcode")
    IO.inspect(pkt, limit: :infinity)
    IO.puts("")
  end
end
