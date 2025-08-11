defmodule LiveDataFeed.Simulators.ClientSimulator do
  @moduledoc """
  A GenServer that simulates a client subscribing to stock price updates.

  Maintains a set of subscribed stock symbols and manages PubSub subscriptions
  for those symbols. Handles incoming stock update messages by logging them.

  Provides functions to subscribe and unsubscribe from stock symbols, validating
  symbols against the configured price fetcher.
  """

  use GenServer

  require Logger

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, :unknown_client)
    GenServer.start_link(__MODULE__, %{subscriptions: MapSet.new(), name: name}, opts)
  end

  def init(state), do: {:ok, state}

  def subscribe_to_symbol(pid, symbol) do
    if symbol in available_symbols() do
      GenServer.call(pid, {:subscribe, symbol})
    else
      {:error, :invalid_symbol}
    end
  end

  def unsubscribe_from_symbol(pid, symbol) do
    if symbol in available_symbols() do
      GenServer.call(pid, {:unsubscribe, symbol})
    else
      {:error, :invalid_symbol}
    end
  end

  def handle_call({:subscribe, symbol}, _from, %{subscriptions: subs, name: name} = state) do
    if MapSet.member?(subs, symbol) do
      {:reply, :ok, state}
    else
      topic = "stocks:#{symbol}"
      :ok = Phoenix.PubSub.subscribe(LiveDataFeed.PubSub, topic)

      Logger.info(
        "[PID #{inspect(self())} | Client #{inspect(name)}] Subscribed to #{inspect(topic)}"
      )

      {:reply, :ok, %{state | subscriptions: MapSet.put(subs, symbol)}}
    end
  end

  def handle_call({:unsubscribe, symbol}, _from, %{subscriptions: subs, name: name} = state) do
    topic = "stocks:#{symbol}"
    :ok = Phoenix.PubSub.unsubscribe(LiveDataFeed.PubSub, topic)

    Logger.info(
      "[PID #{inspect(self())} | Client #{inspect(name)}] Unsubscribed from #{inspect(topic)}"
    )

    {:reply, :ok, %{state | subscriptions: MapSet.delete(subs, symbol)}}
  end

  def handle_info(%{symbol: symbol} = msg, %{name: name} = state) do
    Logger.info(
      "[PID #{inspect(self())} | Client #{inspect(name)}] Received update from #{inspect(symbol)}: #{inspect(msg, pretty: true)}"
    )

    {:noreply, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp available_symbols do
    price_fetcher =
      Application.get_env(
        :live_data_feed,
        __MODULE__,
        stock_price_fetcher: LiveDataFeed.LocalPriceFetcher
      )[:stock_price_fetcher]

    price_fetcher.available_symbols()
  end
end
