defmodule BrewingStand.MixProject do
  use Mix.Project

  def project do
    [
      app: :brewing_stand,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {BrewingStand.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:typed_struct, "~> 0.2.1"},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end

  def aliases do
    [
      "bench.block_ordering": ["run --no-start priv/bench/block_ordering.exs"]
    ]
  end
end
