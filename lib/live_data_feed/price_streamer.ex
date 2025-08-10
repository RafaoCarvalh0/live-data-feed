defmodule LiveDataFeed.PriceStreamer do
  use GenServer

  alias LiveDataFeed.Stock.StockService

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

    Enum.each(prices, fn %{symbol: symbol, current_price: price, timestamp: ts, volume: vol} ->
      price_in_cents = price * 100

      last_price =
        last_stock_data_lookup
        |> Map.get(symbol, %{})
        |> Map.get(:price, 0)

      price_change = price_in_cents - last_price

      price_change_percent =
        if last_price != 0 do
          (price_in_cents - last_price) / last_price * 100
        else
          0
        end

      Phoenix.PubSub.broadcast(LiveDataFeed.PubSub, "stocks:#{symbol}", %{
        symbol: symbol,
        current_price: price_in_cents,
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
end
