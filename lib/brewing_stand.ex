defmodule BrewingStand do
  require Logger
  alias BrewingStand.{Packets, Util, World}

  @identify 0x00
  @protocol 0x07

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:list, packet: :raw, active: false, reuseaddr: true])

    # TODO: store worlds in ETS alongside clients? - also means moving world dimensions to the same table probably.
    world = World.new(256, 64, 256, :world, :flat)

    Logger.info("Accepting connections on port #{port}")
    loop(socket, world)
  end

  def loop(socket, world) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} =
      Task.Supervisor.start_child(BrewingStand.TaskSupervisor, fn -> serve(client, world) end)

    :ok = :gen_tcp.controlling_process(client, pid)

    loop(socket, world)
  end

  def serve(socket, world) do
    # TODO: store clients in ETS(?) to send global events when needed
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} -> parse_packet(socket, data, world)
      {:error, :closed} -> exit(:shutdown)
      e -> Logger.error(inspect(e))
    end
  end

  def parse_packet(socket, [@identify | packet], world) do
    Logger.debug("Got IDENTIFY packet")

    with [@protocol | data] <- packet,
         {:ok, username, data} <- Util.next_string(data),
         {:ok, key, data} <- Util.next_string(data),
         [_unused] <- data do
      IO.inspect(username)
      # TODO: key validation?
      IO.inspect(key)

      Packets.server_identify(socket, username)
      send_world(socket, world)
      # TODO: debug - player spawns in the world corner for some reason
      Packets.spawn_player(socket, username, 32, 5, 32)
      Packets.teleport_player(socket, 32, 5, 32)

      # TODO: set up intermittent pings with client - Do this after moving all
      # clients/sockets to an ETS table so that we can easily ping them all at
      # once.
    else
      [version | _] -> gtfo(socket, "Unknown protocol version #{version}. Expected #{@protocol}.")
      _ -> gtfo(socket, "Bad identify packet.")
    end
  end

  def parse_packet(_socket, packet, _world), do: IO.inspect(packet)

  def send_world(socket, world) do
    chunks = World.to_level_data(world)
    chunks_len = length(chunks)

    Packets.level_init(socket)

    for {chunk, idx} <- Enum.with_index(chunks, 1) do
      percentage = (idx / chunks_len * 100) |> trunc()
      Packets.level_chunk(socket, chunk, percentage)
    end

    Packets.level_finalize(socket, world.x, world.y, world.z)
  end

  defp gtfo(socket, reason) do
    if reason != nil, do: :gen_tcp.send(socket, reason)
    :gen_tcp.close(socket)
    exit(:shutdown)
  end
end
