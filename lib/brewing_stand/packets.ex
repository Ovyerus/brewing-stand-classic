defmodule BrewingStand.Packets do
  require Logger

  import BrewingStand.Util
  alias BrewingStand.Player

  @type sbyte :: -127..127
  @type short :: -32767..32767
  @type packet :: list(byte())

  @identify 0x00
  @ping 0x01
  @level_initialize 0x02
  @level_chunk 0x03
  @level_finalize 0x04
  @spawn_player 0x07
  @despawn_player 0x0C
  @message 0x0D

  @protocol 0x07

  @server_name pad_string("Minecraft Server")
  @server_motd pad_string("Running BrewingStand 0.0.1")

  @spec broadcast(binary(), sbyte() | nil) :: :ok
  def broadcast(packet, exclude \\ nil) do
    players =
      case exclude do
        nil -> Player.all()
        id -> Player.all_but(id)
      end

    for player <- players do
      :gen_tcp.send(player.socket, packet)
    end

    :ok
  end

  def server_identify(op \\ 0x00),
    do: <<@identify, @protocol, @server_name, @server_motd, op>>

  def ping, do: <<@ping>>
  def level_initialize, do: <<@level_initialize>>

  @spec level_chunk(binary(), byte()) :: binary()
  def level_chunk(chunk, percentage),
    do: <<@level_chunk>> <> to_short(byte_size(chunk)) <> pad_byte_array(chunk) <> <<percentage>>

  @spec level_finalize(short(), short(), short()) :: binary()
  def level_finalize(x, y, z),
    do: <<@level_finalize>> <> to_short(x) <> to_short(y) <> to_short(z)

  # def level_chunk(socket, chunk, percentage) do
  #   Logger.debug("Sending level chunk, #{percentage}% complete")

  #   :gen_tcp.send(
  #     socket,
  #     [@level_chunk, to_short(length(chunk)), pad_byte_array(chunk), percentage] |> List.flatten()
  #   )
  # end

  @spec spawn_player(sbyte(), String.t(), float(), float(), float(), byte(), byte()) :: binary()
  def spawn_player(id, username, x, y, z, yaw \\ 0, pitch \\ 0),
    do:
      <<
        @spawn_player,
        to_sbyte(id),
        username::binary
      >> <>
        to_fp_short(x) <>
        to_fp_short(y) <>
        to_fp_short(z) <>
        <<yaw, pitch>>

  @spec teleport_player(sbyte(), float(), float(), float(), byte(), byte()) :: binary()
  def teleport_player(id, x, y, z, yaw \\ 0, pitch \\ 0),
    do:
      <<
        @spawn_player,
        to_sbyte(id)
      >> <>
        to_fp_short(x) <>
        to_fp_short(y) <>
        to_fp_short(z) <>
        <<yaw, pitch>>

  @spec despawn_player(sbyte()) :: binary()
  def despawn_player(id), do: <<@despawn_player, to_sbyte(id)>>

  # @spec message(sbyte(), String.t()) :: binary()
  # def message(id, message), do: [@message, to_sbyte(id), pad_string(message)] |> List.flatten()
end
