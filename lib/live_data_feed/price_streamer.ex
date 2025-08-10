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

    Enum.each(prices, fn {symbol, price} ->
      Phoenix.PubSub.broadcast(LiveDataFeed.PubSub, "stocks:#{symbol}", %{
        symbol: symbol,
        price: price
      })
    end)

    schedule_update()
    {:noreply, state}
  end

  defp schedule_update do
    Process.send_after(self(), :update, @interval_in_ms)
  end
end
