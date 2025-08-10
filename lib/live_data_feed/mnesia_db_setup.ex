defmodule LiveDataFeed.MnesiaDbSetup do
  def start_mnesia() do
    :mnesia.stop()

    case :mnesia.create_schema([node()]) do
      :ok -> IO.puts("Mnesia schema created")
      {:error, {_, {:already_exists, _}}} -> :ok
    end

    :mnesia.start()

    case :mnesia.create_table(:stock_prices, [
           {:attributes, [:symbol, :price_cents, :timestamp]},
           {:disc_copies, [node()]},
           {:type, :set}
         ]) do
      {:atomic, :ok} -> IO.puts("Table :stock_prices created")
      {:aborted, {:already_exists, :stock_prices}} -> :ok
    end
  end
end
