defmodule BrewingStandTest do
  use ExUnit.Case
  doctest BrewingStand

  test "greets the world" do
    assert BrewingStand.hello() == :world
  end
end
