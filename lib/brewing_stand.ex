defmodule BrewingStand do
  require Logger
  alias BrewingStand.{Packets, Util}

  @identify 0x00
  @protocol 0x07

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:list, packet: :raw, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop(socket)
  end

  def loop(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(BrewingStand.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)

    loop(socket)
  end

  def serve(socket) do
    # TODO: store clients in ETS(?) to send global events when needed
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} -> parse_packet(socket, data)
      {:error, :closed} -> exit(:shutdown)
      e -> Logger.error(inspect(e))
    end
  end

  def parse_packet(socket, [@identify | packet]) do
    Logger.debug("Got IDENTIFY packet")

    with [@protocol | data] <- packet,
         {:ok, username, data} <- Util.next_string(data),
         {:ok, key, data} <- Util.next_string(data),
         [_unused] <- data do
      IO.inspect(username)
      # TODO: key validation
      IO.inspect(key)

      Packets.server_identify(socket, username)
      send_level(socket)
      Packets.spawn_player(socket, username)
    else
      [version | _] -> gtfo(socket, "Unknown protocol version #{version}. Expected #{@protocol}.")
      _ -> gtfo(socket, "Bad packet.")
    end
  end

  def parse_packet(_socket, packet), do: IO.inspect(packet)

  def send_level(socket) do
    # not working, need to figure out level format
    Packets.level_init(socket)
    Packets.level_chunk(socket, 0)
    Process.sleep(1000)
    Packets.level_chunk(socket, 25)
    Process.sleep(1000)
    Packets.level_chunk(socket, 50)
    Process.sleep(1000)
    Packets.level_chunk(socket, 75)
    Process.sleep(1000)
    Packets.level_chunk(socket, 100)
    Packets.level_finalize(socket, 16, 16, 16)
  end

  defp gtfo(socket, reason) do
    if reason != nil, do: :gen_tcp.send(socket, reason)
    :gen_tcp.close(socket)
    exit(:shutdown)
  end
end
