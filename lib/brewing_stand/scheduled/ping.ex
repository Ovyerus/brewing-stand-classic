defmodule BrewingStand.Scheduled.Ping do
  # 5 seconds
  use BrewingStand.Scheduled, interval: 5 * 1000
  require Logger
  import BrewingStand.Packets

  def run do
    for [{id, player}] <- :ets.match(:players, :"$1") do
      with :ok <- :gen_tcp.send(player.socket, ping()),
           true <- Process.alive?(player.pid) do
        :noop
      else
        false ->
          Logger.warn(
            "Process #{inspect(player.pid)} for player #{player.username} terminated, dunno why."
          )

          gtfo(id, player)

        {:error, :closed} ->
          Logger.info("#{player.username} has left the server.")
          gtfo(id, player)

        {:error, reason} ->
          Logger.warn("Failed to ping #{player.username} (#{reason}); disconnecting from server.")
          gtfo(id, player)
      end
    end
  end

  defp gtfo(id, player) do
    :ets.delete(:players, id)

    if Process.alive?(player.pid) == true, do: Process.exit(player.pid, :shutdown)
    if :erlang.port_info(player.socket) != :undefined, do: :gen_tcp.close(player.socket)

    broadcast(despawn_player(player.id), player.id)
  end
end
