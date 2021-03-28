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
      # Packets.level_init(socket)
      # send_level(socket)
    else
      [version | _] -> Logger.warn("Unknown protocol version for IDENTIFY: #{version}")
      e -> Logger.error(e)
    end
  end

  def parse_packet(_socket, packet), do: IO.inspect(packet)

  # def send_level(socket) do

  # end
end
