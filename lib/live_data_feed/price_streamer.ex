defmodule LiveDataFeed.PriceStreamer do
  use GenServer

  @symbols ["AAPL", "GOOG", "TSLA", "AMZN"]
  @interval_in_ms 1_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: :price_streamer)
  end

  def init(state) do
    schedule_tick()
    {:ok, state}
  end

  def handle_info(:tick, state) do
    Enum.each(@symbols, fn symbol ->
      price_in_cents = :rand.uniform(100_000)

      Phoenix.PubSub.broadcast(LiveDataFeed.PubSub, "stocks:#{symbol}", %{
        symbol: symbol,
        price: price_in_cents
      })
    end)

    schedule_tick()
    {:noreply, state}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @interval_in_ms)
  end
end
