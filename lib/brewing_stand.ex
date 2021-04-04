defmodule BrewingStand do
  require Logger
  alias BrewingStand.{PacketReader, World}

  def start(port) do
    case :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true]) do
      {:ok, socket} ->
        # TODO: store worlds in ETS alongside clients? - also means moving world
        # dimensions to the same table probably. also track of current world -
        # (per client?)
        :ets.new(:players, [:set, :public, :named_table])
        world = World.new(256, 64, 256, :woworld, :flat)

        Logger.info("Accepting connections on port #{port}")
        accept(socket, world)

      {:error, reason} ->
        Logger.error("Failed to start server, #{reason}")
        System.stop(1)
    end
  end

  def accept(socket, world) do
    with {:ok, client} <- :gen_tcp.accept(socket),
         {:ok, pid} <-
           Task.Supervisor.start_child(BrewingStand.Tasks, fn ->
             PacketReader.serve(client, world)
           end),
         :ok <- :gen_tcp.controlling_process(client, pid) do
      accept(socket, world)
    else
      {:error, reason} -> Logger.error("Failed to accept a connection, #{reason}")
    end
  end
end
