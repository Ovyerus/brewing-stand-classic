defmodule BrewingStand.Scheduled do
  @moduledoc """
  A behaviour for easily defining a task to be run on an interval.
  """

  defmacro __using__(interval: interval) do
    quote do
      use GenServer
      @behaviour BrewingStand.Scheduled

      def start_link(_), do: GenServer.start_link(__MODULE__, %{})

      def init(state) do
        schedule()
        {:ok, state}
      end

      def handle_info(:work, state) do
        run()
        schedule()

        {:noreply, state}
      end

      defp schedule, do: Process.send_after(self(), :work, unquote(interval))
    end
  end

  @callback run() :: any()
end
