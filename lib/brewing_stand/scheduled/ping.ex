defmodule BrewingStand.Scheduled.Ping do
  # 5 seconds
  use BrewingStand.Scheduled, interval: 5 * 1000
  require Logger
  import BrewingStand.Packets

  def run do
    for [{id, player}] <- :ets.match(:players, :"$1") do
      case :gen_tcp.send(player.socket, ping()) do
        :ok ->
          :noop

        {:error, :closed} ->
          Logger.info("#{player.username || player.id} has left the server.")

          Process.exit(player.pid, :shutdown)
          :ets.delete(:players, id)

          # TODO: broadcast leave message?
          broadcast(despawn_player(player.id))

        {:error, reason} ->
          Logger.info(
            "Failed to ping #{player.username || player.id} (#{reason}); disconnecting from server."
          )

          :gen_tcp.close(player.socket)
          Process.exit(player.pid, :shutdown)
          :ets.delete(:players, id)

          broadcast(despawn_player(player.id))
      end
    end
  end
end
