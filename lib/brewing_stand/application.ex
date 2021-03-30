defmodule BrewingStand.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "25565")

    children = [
      {Task.Supervisor, name: BrewingStand.Tasks},
      Supervisor.child_spec({Task, fn -> BrewingStand.start(port) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: BrewingStand.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
