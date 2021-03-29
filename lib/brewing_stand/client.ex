defmodule BrewingStand.Client do
  require Logger

  alias BrewingStand.Client.{Level, PacketReader}
  import BrewingStand.Util

  def start do
    Level.init()

    case :gen_tcp.connect({127, 0, 0, 1}, 25565, [:list, :inet, packet: :raw, active: false]) do
      {:ok, socket} ->
        Logger.info("Connected to 127.0.0.1:25565")
        loop(socket)

      {:error, :econnrefused} ->
        Logger.error("Unable to connect to server ECONNREFUSED")
        System.stop(1)

      e ->
        IO.inspect(e)
        System.stop(1)
    end
  end

  def loop(socket) do
    # Identify to kick things off
    username = pad_string('Testy')
    key = pad_string('(none)')
    packet = [0x00, 0x07, username, key, 0x00] |> List.flatten()

    Logger.debug("Sent identify")
    :gen_tcp.send(socket, packet)

    PacketReader.read(socket)
  end
end
