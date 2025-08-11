defmodule LiveDataFeed.MnesiaDbSetup do
  require Logger

  def start_mnesia() do
    env = Application.get_env(:live_data_feed, :env)

    if env != :test do
      Logger.info("Starting Mnesia setup")
      :mnesia.stop()

      case :mnesia.create_schema([node()]) do
        :ok -> IO.puts("Mnesia schema created")
        {:error, {_, {:already_exists, _}}} -> :ok
      end

      :mnesia.start()

      storage_type = :disc_copies

      case :mnesia.create_table(:stock_prices, [
             {:attributes, [:symbol, :price_in_cents]},
             {storage_type, [node()]},
             {:type, :set}
           ]) do
        {:atomic, :ok} -> IO.puts("Table :stock_prices created")
        {:aborted, {:already_exists, :stock_prices}} -> :ok
      end

      :mnesia.wait_for_tables([:stock_prices], 5000)
      Logger.info("Setup concluded")
    end
  end
end
