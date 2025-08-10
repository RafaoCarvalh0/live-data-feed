defmodule LiveDataFeed.PriceStreamer do
  use GenServer

  require Logger

  @interval_in_ms 2_000

  def start_link(opts \\ []) do
    stock_price_fetcher = Keyword.get(opts, :stock_price_fetcher, LiveDataFeed.LocalPriceFetcher)

    GenServer.start_link(__MODULE__, %{stock_price_fetcher: stock_price_fetcher}, opts)
  end

  def init(state) do
    schedule_update()
    {:ok, state}
  end

  def handle_info(:update, %{stock_price_fetcher: stock_price_fetcher} = state) do
    prices = stock_price_fetcher.fetch_prices()

    # TODO: add mnesia to store last value
    Enum.each(prices, fn %{symbol: symbol, current_price: price, timestamp: ts, volume: vol} ->
      Phoenix.PubSub.broadcast(LiveDataFeed.PubSub, "stocks:#{symbol}", %{
        symbol: symbol,
        current_price: price,
        last_price: 0,
        price_change: 0,
        price_change_percent: 0,
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
end
