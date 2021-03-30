defmodule BrewingStand.Packets do
  require Logger

  # alias BrewingStand.Util
  import BrewingStand.Util

  @identify 0x00
  @level_initialize 0x02
  @level_chunk 0x03
  @level_finalize 0x04
  @spawn_player 0x07

  @protocol 0x07
  @not_op 0x00
  @op 0x64

  @server_name pad_string('Minecraft Server')
  @server_motd pad_string('Running BrewingStand 0.0.1')

  def server_identify(socket) do
    # TODO: get user type based on username.
    :gen_tcp.send(
      socket,
      [@identify, @protocol, @server_name, @server_motd, @not_op]
      |> List.flatten()
    )
  end

  def level_init(socket) do
    Logger.debug("Initializing world")
    :gen_tcp.send(socket, [@level_initialize])
  end

  def level_chunk(socket, chunk, percentage) do
    Logger.debug("Sending level chunk, #{percentage}% complete")

    :gen_tcp.send(
      socket,
      [@level_chunk, to_short(length(chunk)), pad_byte_array(chunk), percentage] |> List.flatten()
    )
  end

  def level_finalize(socket, x, y, z) do
    Logger.debug("Finalizing world")

    :gen_tcp.send(
      socket,
      [@level_finalize, to_short(x), to_short(y), to_short(z)] |> List.flatten()
    )
  end

  # TOOD: what do other player IDs do?
  def spawn_player(socket, username, x, y, z, yaw \\ 0, pitch \\ 0) do
    :gen_tcp.send(
      socket,
      [
        @spawn_player,
        to_sbyte(-1),
        username,
        to_short(x),
        to_short(y),
        to_short(z),
        yaw,
        pitch
      ]
      |> List.flatten()
    )
  end

  def teleport_player(socket, x, y, z, yaw \\ 0, pitch \\ 0) do
    :gen_tcp.send(
      socket,
      [
        @spawn_player,
        to_sbyte(-1),
        to_short(x),
        to_short(y),
        to_short(z),
        yaw,
        pitch
      ]
      |> List.flatten()
    )
  end
end
