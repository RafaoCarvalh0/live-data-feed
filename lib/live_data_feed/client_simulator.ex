defmodule LiveDataFeed.ClientSimulator do
  use GenServer

  require Logger

  @available_symbols ["AAPL", "GOOG", "TSLA", "AMZN"]

  def start_link(symbol) when symbol in @available_symbols do
    GenServer.start_link(__MODULE__, symbol)
  end

  def start_link(_) do
    {:error, :invalid_symbol}
  end

  def init(symbol) do
    topic = "stocks:#{symbol}"

    Phoenix.PubSub.subscribe(LiveDataFeed.PubSub, topic)

    Logger.info("[ClientSimulator #{inspect(symbol)}] Subscribed to #{inspect(topic)}")

    {:ok, symbol}
  end

  def handle_info(%{symbol: symbol, price: price_in_cents} = _msg, state) do
    Logger.info(
      "[ClientSimulator #{inspect(symbol)}] Received update: #{inspect(price_in_cents)} cents"
    )

    {:noreply, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}
end
