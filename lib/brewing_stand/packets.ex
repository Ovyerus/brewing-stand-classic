defmodule BrewingStand.Packets do
  require Logger
  alias BrewingStand.Util

  @identify 0x00
  @level_initialize 0x02
  @level_chunk 0x03
  @level_finalize 0x04

  @protocol 0x07
  @not_op 0x00
  @op 0x64

  @server_name Util.pad_string('Minecraft Server')
  @server_motd Util.pad_string('Running BrewingStand 0.0.1')

  def server_identify(socket, username) do
    Logger.debug("Sending IDENTIFY to #{username}")
    # TODO: get user type based on username.

    :gen_tcp.send(
      socket,
      [@identify, @protocol, @server_name, @server_motd, @not_op]
      |> List.flatten()
    )
  end

  def level_init(socket), do: :gen_tcp.send(socket, [@level_initialize])
  # def level_finalize(socket, x, y, z), do: :gen_tcp.send(socket, [@level_finalize,])
end
