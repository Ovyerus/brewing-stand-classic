defmodule BrewingStand.DummyClient.Level do
  @table :level

  def init() do
    :ets.new(@table, [:named_table, :set, :public])
    :ets.insert(@table, {:chunks, []})
    :ok
  end

  def add(chunk) do
    [{:chunks, chunks}] = :ets.lookup(@table, :chunks)
    chunks = chunks ++ chunk

    :ets.insert(@table, {:chunks, chunks})
    :ok
  end

  def get_world() do
    case :ets.lookup(@table, :completed) do
      [] ->
        [{:chunks, chunks}] = :ets.lookup(@table, :chunks)
        decompressed = :zlib.unzip(chunks)
        :ets.insert(@table, {:completed, decompressed})
        decompressed

      [{:completed, data}] ->
        data
    end
  end
end
