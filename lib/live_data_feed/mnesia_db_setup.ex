defmodule LiveDataFeed.MnesiaDbSetup do
  require Logger

  def start_mnesia() do
    env = Application.get_env(:live_data_feed, :env)

    if env != :test do
      Logger.info("Starting Mnesia setup")

      :mnesia.stop()

      case :mnesia.create_schema([node()]) do
        :ok -> Logger.info("Mnesia schema created")
        {:error, {_, {:already_exists, _}}} -> :ok
      end

      :mnesia.start()

      case :mnesia.create_table(:stock_prices, [
             {:attributes, [:symbol, :price_in_cents]},
             {:disc_copies, [node()]},
             {:type, :set}
           ]) do
        {:atomic, :ok} -> Logger.info("Table :stock_prices created")
        {:aborted, {:already_exists, :stock_prices}} -> :ok
      end

      :mnesia.wait_for_tables([:stock_prices], 5000)
      Logger.info("Setup concluded")
    end
  end
end
