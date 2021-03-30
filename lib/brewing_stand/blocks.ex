defmodule BrewingStand.Blocks do
  use BrewingStand.Util.Macros

  defmacro __using__(_) do
    quote do
      require BrewingStand.Blocks
      alias BrewingStand.Blocks
    end
  end

  defenum [
    :air,
    :stone,
    :grass,
    :dirt,
    :cobblestone,
    :planks,
    :sapling,
    :bedrock,
    :water_flowing,
    :water_still,
    :lava_flowing,
    :lava_still,
    :sand,
    :gravel,
    :gold_ore,
    :iron_ore,
    :coal_ore,
    :wood,
    :leaves,
    :sponge,
    :glass,
    :cloth_red,
    :cloth_orange,
    :cloth_yellow,
    :cloth_lime,
    :cloth_green,
    :cloth_aqua,
    :cloth_cyan,
    :cloth_blue,
    :cloth_purple,
    :cloth_indigo,
    :cloth_violet,
    :cloth_magenta,
    :cloth_pink,
    :cloth_black,
    :cloth_grey,
    :cloth_white,
    :dandelion,
    :rose,
    :mushroom_brown,
    :mushroom_red,
    :gold_block,
    :iron_block,
    :slab_double,
    :slab,
    :brick,
    :tnt,
    :bookself,
    :cobblestone_moss,
    :obsidian
  ]
end
