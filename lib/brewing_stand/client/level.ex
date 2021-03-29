defmodule BrewingStand.Client.Level do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [])
  def add_gzip_chunk(pid, chunk), do: GenServer.cast(pid, {:add_gzip_chunk, chunk})
  def get_world(pid), do: GenServer.call(pid, {:get_world})

  # Callbacks

  def init(_state) do
    {:ok, %{world: nil, data: []}}
  end

  def handle_cast({:add_gzip_chunk, chunk}, %{data: data} = state) do
    {:noreply, %{state | data: data ++ chunk}}
    # Put chunks in backwards bc fast. Reverse later
    # {:noreply, %{state | data: [chunk | data]}}
  end

  def handle_call({:get_world}, _from, %{world: world, data: data} = state) do
    case world do
      nil ->
        # data = data |> Enum.reverse() |> List.flatten()
        data = data |> List.flatten()
        # TODO: this no work. Why?
        # decompressed = :zlib.unzip(data)
        # {:reply, decompressed, %{state | world: decompressed}}
        {:reply, data, %{state | world: data}}

      world ->
        {:reply, world, state}
    end
  end
end
