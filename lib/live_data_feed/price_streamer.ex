defmodule LiveDataFeed.PriceStreamer do
  @moduledoc """
  Periodically fetches stock prices, updates stored stock data, and broadcasts updates.

  This GenServer acts as the core component responsible for:
  - Periodic polling of stock prices from a configurable price fetcher.
  - Comparing the latest prices with previously stored data.
  - Persisting updated stock data through `StockService`.
  - Broadcasting detailed price updates (including price changes and percentage changes)
    to subscribed clients via Phoenix PubSub topics.

  The module ensures continuous updates at fixed intervals (`@interval_in_ms`),
  and handles graceful shutdown by attempting to persist the last known stock data.

  ## Responsibilities
  - Schedule periodic fetches and broadcasts of stock prices.
  - Maintain price change calculations and include them in broadcasted messages.
  - Use the configured stock price fetcher, defaulting to `LiveDataFeed.LocalPriceFetcher`.
  - Delegate stock data storage and validation to `StockService`.
  """

  use GenServer

  alias LiveDataFeed.Stock.StockService

  require Logger

  @interval_in_ms 3_000

  def start_link(opts \\ []) do
    stock_price_fetcher = Keyword.get(opts, :stock_price_fetcher, LiveDataFeed.LocalPriceFetcher)

    GenServer.start_link(__MODULE__, %{stock_price_fetcher: stock_price_fetcher}, opts)
  end

  def init(state) do
    Logger.info("Starting Price Streamer with pid #{inspect(self())}")

    schedule_update()
    {:ok, state}
  end

  def handle_info(:update, %{stock_price_fetcher: stock_price_fetcher} = state) do
    prices = stock_price_fetcher.fetch_prices()

    last_stock_data_lookup =
      case StockService.get_stocks_data() do
        [_ | _] = data ->
          data
          |> Enum.group_by(& &1.symbol)
          |> Enum.map(fn {symbol, [last | _]} -> {symbol, last} end)
          |> Map.new()

        _ ->
          %{}
      end

    prices
    |> Enum.map(&%{symbol: &1.symbol, price: &1.current_price})
    |> StockService.set_stocks_data()

    Enum.each(prices, fn %{symbol: symbol, current_price: price, timestamp: ts, volume: vol} ->
      last_price =
        last_stock_data_lookup
        |> Map.get(symbol, %{})
        |> Map.get(:price, 0)

      price_change = price - last_price

      price_change_percent =
        if last_price != 0 do
          round((price - last_price) / last_price * 100)
        else
          0
        end

      Phoenix.PubSub.broadcast(LiveDataFeed.PubSub, "stocks:#{symbol}", %{
        symbol: symbol,
        current_price: price,
        last_price: last_price,
        price_change: price_change,
        price_change_percent: price_change_percent,
        timestamp: ts,
        volume: vol
      })
    end)

    schedule_update()
    {:noreply, state}
  end

  defp schedule_update do
    Process.send_after(self(), :update, @interval_in_ms)
  end

  def terminate(_reason, %{stock_price_fetcher: fetcher}) do
    Logger.warning("Gracefully shutting down: saving snapshot of most recent stock updates.")

    try_to_persist_last_stock_updates(fetcher)
  end

  defp try_to_persist_last_stock_updates(stock_price_fetcher) do
    stock_price_fetcher.fetch_prices()
    |> Enum.map(fn %{symbol: symbol, current_price: price} ->
      %{
        symbol: symbol,
        price: price * 100
      }
    end)
    |> StockService.set_stocks_data()
    |> case do
      :ok -> Logger.info("Snapshot saved successfully.")
      _ -> Logger.warning("Snapshot could not be saved.")
    end
  end
end
