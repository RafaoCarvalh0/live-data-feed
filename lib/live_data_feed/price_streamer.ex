defmodule LiveDataFeed.PriceStreamer do
  use GenServer

  require Logger

  @symbols ["AAPL", "GOOG", "TSLA", "AMZN"]
  @interval_in_ms 2_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def init(state) do
    schedule_update()
    {:ok, state}
  end

  def handle_info(:update, state) do
    Enum.each(@symbols, fn symbol ->
      price_in_cents =
        :rand.uniform(100_000)

      Phoenix.PubSub.broadcast(LiveDataFeed.PubSub, "stocks:#{symbol}", %{
        symbol: symbol,
        price: price_in_cents
      })
    end)

    schedule_update()
    {:noreply, state}
  end

  defp schedule_update do
    Process.send_after(self(), :update, @interval_in_ms)
  end
end
