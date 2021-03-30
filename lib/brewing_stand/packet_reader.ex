defmodule BrewingStand.PacketReader do
  require Logger

  import BrewingStand.Packets
  import BrewingStand.Util
  alias BrewingStand.World

  @dialyzer {:no_match, handle_packet: 4}

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
    with {:ok, [op]} <- read(socket, 1),
         {len, _} when len not in [0, nil] <- {@op_codes[op], op},
         {:ok, packet} <- read(socket, len) do
      handle_packet(op, packet, world, socket)
      serve(socket, world)
    else
      {0, op} ->
        handle_packet(op, [], socket, world)
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

  defp handle_packet(0x00, packet, world, socket) do
    with [@protocol | packet] <- packet,
         {:ok, username, packet} <- next_string(packet),
         {:ok, _key, packet} <- next_string(packet),
         [_unused] <- packet do
      Logger.info("#{username} has joined the server!")

      server_identify(socket)
      send_world(socket, world)
      # TODO: debug - player spawns in the world corner for some reason
      spawn_player(socket, username, 32, 32, 32)
      teleport_player(socket, 32, 32, 32)
    else
      [version] -> kill(socket, "Unknown protocol version #{version}.")
      _ -> kill("Bad packet.")
    end
  end

  defp handle_packet(op, packet, _world, _socket) do
    IO.inspect(op)
    IO.inspect(packet, limit: :infinity)
  end

  defp send_world(socket, world) do
    chunks = World.to_level_data(world)
    chunks_len = length(chunks)

    level_init(socket)

    for {chunk, idx} <- Enum.with_index(chunks, 1) do
      percentage = (idx / chunks_len * 100) |> trunc()
      level_chunk(socket, chunk, percentage)
    end

    level_finalize(socket, world.x, world.y, world.z)
  end

  defp kill(socket, reason \\ nil) do
    if reason != nil, do: :gen_tcp.send(socket, reason)
    :gen_tcp.close(socket)
    exit(:shutdown)
  end
end
