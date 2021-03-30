defmodule BrewingStand.World do
  @moduledoc """
  A struct representing a Minecraft world.
  """

  use TypedStruct
  use BrewingStand.Blocks

  @type axis :: pos_integer()
  @type world_type :: :empty | :flat

  typedstruct enforce: true do
    @typedoc "A Minecraft world"

    field(:x, axis())
    field(:y, axis())
    field(:z, axis())
    field(:name, atom())
  end

  @spec new(axis(), axis(), axis(), atom(), world_type()) :: t()
  def new(x, y, z, name, type)

  def new(x, y, z, name, :empty) do
    if x <= 0 or y <= 0 or z <= 0,
      do: raise("Cannot create a world with any axis that isn't above 0 (#{x},#{y},#{z}).")

    world = %__MODULE__{x: x, y: y, z: z, name: name}

    :ets.new(name, [:public, :ordered_set, :named_table])
    generate_empty(world)

    world
  end

  def new(x, y, z, name, :flat) do
    if x <= 0 or y <= 0 or z <= 0,
      do: raise("Cannot create a world with any axis that isn't above 0 (#{x},#{y},#{z}).")

    world = %__MODULE__{x: x, y: y, z: z, name: name}

    :ets.new(name, [:public, :ordered_set, :named_table])
    generate_flat(world)

    world
  end

  @spec get_blocks(t()) :: map()
  @doc """
  Get a map of all blocks for the given world.
  """
  def get_blocks(%__MODULE__{name: name}),
    do: :ets.match(name, :"$1") |> Enum.map(&Enum.at(&1, 0)) |> Enum.into(%{})

  # TODO: get_block & set_block

  @spec to_level_data(t()) :: list(list(byte()))
  @doc """
  Convert a world into a list of byte chunks to send to a client.
  """
  def to_level_data(%__MODULE__{x: width, y: height, z: length, name: name}) do
    blocks =
      :ets.match(name, :"$1")
      # Weird block order sorting. Needed in order to properly order blocks for
      # the Minecraft client to receive the right order. Doesn't seem to be
      # perfect however - there's a weird partial 5th layer on the flat
      # generation below - don't know if that's somehow a fault in my generator,
      # or this though.
      # Reference: https://fire.is-fi.re/4LnN37N.png
      |> Enum.sort_by(fn [{{x, y, z}, _}] ->
        x + width * (z + y * length)
      end)
      |> Enum.map(fn [{_, block_id}] -> block_id end)

    <<b1, b2, b3, b4>> = <<width * height * length::32>>
    # 4 byte header indicating world size, followed by list of block ids
    data = [b1, b2, b3, b4 | blocks] |> :zlib.gzip() |> :binary.bin_to_list()
    chunks = data |> Enum.chunk_every(1024)

    chunks
  end

  # TODO: probably move these to a World.Generator module when i make functioning worldgen
  defp generate_empty(%__MODULE__{x: x, y: y, z: z, name: name}) do
    blocks = for x <- 0..x, y <- 0..y, z <- 0..z, into: [], do: {{x, y, z}, Blocks.air()}
    :ets.insert(name, blocks)
    :ok
  end

  defp generate_flat(%__MODULE__{x: x, z: z, name: name} = world) do
    blocks =
      for x <- 0..x, z <- 0..z, y <- 0..3, into: [] do
        {{x, y, z}, if(y == 3, do: Blocks.grass(), else: Blocks.dirt())}
      end

    generate_empty(world)
    :ets.insert(name, blocks)
    :ok
  end
end
