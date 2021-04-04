defmodule BrewingStand.PacketReader do
  require Logger

  import BrewingStand.Packets
  import BrewingStand.Util
  alias BrewingStand.{Player, World}

  @dialyzer {:no_match, handle_packet: 4}
  @dialyzer {:no_return, kill: 1}

  @protocol 0x07
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
    # Set block (client)
    0x05 => 2 + 2 + 2 + 1 + 1,
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
  }

  def serve(socket, world) do
    with {:ok, <<op>>} <- read(socket, 1),
         {len, _} when len not in [0, nil] <- {@op_codes[op], op},
         {:ok, packet} <- read(socket, len) do
      handle_packet(op, packet, world, socket)
      serve(socket, world)
    else
      {0, op} ->
        handle_packet(op, <<>>, world, socket)
        serve(socket, world)

      {nil, op} ->
        Logger.warn("Unknown opcode #{op}")
        serve(socket, world)

      {:stopped} ->
        kill(socket)
        nil

      {:error} ->
        serve(socket, world)
    end
  end

  defp read(socket, len) do
    case :gen_tcp.recv(socket, len) do
      {:ok, _} = r ->
        r

      {:error, :closed} ->
        kill(socket)
        {:stopped}

      e ->
        Logger.error(inspect(e))
        {:error}
    end
  end

  @spec handle_packet(byte(), binary(), World.t(), :gen_tcp.socket()) :: any()
  defp handle_packet(op_code, packet, world, socket)

  defp handle_packet(0x00, packet, world, socket) do
    # TODO: yell at client if they try send additional identifys
    with <<@protocol, packet::binary>> <- packet,
         {:ok, username, packet} <- next_string(packet),
         {:ok, _key, packet} <- next_string(packet),
         <<_unused>> <- packet do
      :gen_tcp.send(socket, server_identify())
      send_world(socket, world)

      Logger.info("#{username} has joined the server!")
      player = Player.new(socket, self(), username)
      {x, y, z} = {128.5, 64.5, 128.5}

      broadcast(spawn_player(player.id, player.username, x, y, z))
      broadcast(teleport_player(player.id, x, y, z))

      # TODO: debug - player spawns in the world corner for some reason
      :gen_tcp.send(socket, spawn_player(-1, username, x, y, z))
      :gen_tcp.send(socket, teleport_player(-1, x, y, z))
    else
      [version] -> kill(socket, "Unknown protocol version #{version}.")
      _ -> kill(socket, "Bad packet.")
    end
  end

  # defp handle_packet(0x0D, [_unused | packet], _world, socket) do
  #   {:ok, message, []} = next_string(packet)
  #   player = Player.get(socket)

  #   broadcast(message(player.id, message), player.id)
  #   :gen_tcp.send(player, message(-1, message))
  # end

  defp handle_packet(op, packet, _world, _socket) do
    IO.inspect(op)
    IO.inspect(packet, limit: :infinity, charlist: :as_list)
  end

  defp send_world(socket, world) do
    chunks = World.to_level_data(world)
    chunks_len = length(chunks)

    :gen_tcp.send(socket, level_initialize())

    for {chunk, idx} <- Enum.with_index(chunks, 1) do
      percentage = (idx / chunks_len * 100) |> trunc()
      :gen_tcp.send(socket, level_chunk(chunk, percentage))
    end

    :gen_tcp.send(socket, level_finalize(world.x, world.y, world.z))
  end

  defp kill(socket, reason \\ nil) do
    if reason != nil, do: :gen_tcp.send(socket, reason)
    :gen_tcp.close(socket)
    exit(:shutdown)
  end
end
