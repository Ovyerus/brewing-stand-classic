width = 256
height = 64
length = 256

blocks =
  for x <- 0..width, z <- 0..height, y <- 0..31, into: [] do
    [{{x, y, z}, if(y == 31, do: 1, else: 0)}]
  end

Benchee.run(
  %{
    "Enum.sort_by" => fn ->
      blocks
      |> Enum.sort_by(fn [{{x, y, z}, _}] ->
        x + width * (z + y * length)
      end)
      |> Enum.map(fn [{_, id}] -> id end)
    end,
    "Enum.map |> Enum.sort" => fn ->
      blocks
      |> Enum.map(fn [{{x, y, z}, id}] -> {x + width * (z + y * length), id} end)
      |> Enum.sort()
      |> Enum.map(fn {_, id} -> id end)
    end,
    "Stream.map |> Enum.sort" => fn ->
      blocks
      |> Stream.map(fn [{{x, y, z}, id}] -> {x + width * (z + y * length), id} end)
      |> Enum.sort()
      |> Enum.map(fn {_, id} -> id end)
    end
  },
  time: 10,
  memory_time: 2
)
