defmodule BrewingStand.Player do
  @moduledoc """
  A struct representing a connected client.
  """

  @type coord :: non_neg_integer()
  @type id :: 0..127

  use TypedStruct

  typedstruct do
    field(:id, id(), enforce: true)
    field(:username, String.t(), default: nil)
    field(:pid, pid(), enforce: true)
    field(:socket, port(), enforce: true)

    # field(:x, coord(), default: 0)
    # field(:y, coord(), default: 0)
    # field(:z, coord(), default: 0)
    # field(:pitch, float(), default: 0.0)
    # field(:yaw, float(), default: 0.0)
  end

  # TODO: evaluate if need player ID easily searchable by.
  def new(socket, pid, username) do
    id = get_next_available_id()
    player = %__MODULE__{id: id, username: username, pid: pid, socket: socket}

    :ets.insert(:players, {socket, player})
    player
  end

  # def update(%__MODULE__{} = player, options) do
  #   username = Keyword.get(options, :username)
  #   player = %{player | username: username}

  #   :ets.insert(:players, {player.socket})
  # end

  def all(), do: :ets.match(:players, {:_, :"$1"}) |> Stream.map(fn [p] -> p end)

  def all_but(id),
    # fn {_, %{id: p_id}} = x when p_id != id -> x end
    do:
      :ets.select(:players, [{{:_, %{id: :"$1"}}, [{:"/=", :"$1", id}], [:"$_"]}])
      |> Stream.map(fn [{_, p}] -> p end)

  def get(socket) do
    [{_, player}] = :ets.lookup(:players, socket)
    player
  end

  # TODO: would it be faster to get all objects at once?
  defp get_next_available_id(), do: get_next_available_id(0)
  defp get_next_available_id(id) when id > 127, do: raise("Failed to get new ID for player.")

  defp get_next_available_id(id) do
    matchspec = [{{:_, %{id: id}}, [], [:"$_"]}]

    case :ets.select(:players, matchspec) do
      [] -> id
      _ -> get_next_available_id(id + 1)
    end
  end
end
