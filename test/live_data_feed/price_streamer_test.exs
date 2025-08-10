defmodule LiveDataFeed.PriceStreamerTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias LiveDataFeed.PriceStreamer
  alias LiveDataFeed.Stock.StockService

  @symbols ["AAPL", "GOOG", "TSLA", "AMZN"]

  setup do
    original_level = Logger.level()
    Logger.configure(level: :info)

    on_exit(fn ->
      Logger.configure(level: original_level)
    end)
  end

  describe "start_link/1" do
    test "starts the process" do
      assert {:ok, pid} = PriceStreamer.start_link()
      assert Process.alive?(pid)

      GenServer.stop(pid)
    end
  end

  describe "handle_info/2" do
    setup do
      {:ok, pid} = start_supervised(PriceStreamer)

      %{pid: pid}
    end

    test "broadcasts stock price update to subscribers", %{pid: pid} do
      Enum.each(@symbols, &Phoenix.PubSub.subscribe(LiveDataFeed.PubSub, "stocks:#{&1}"))

      force_stock_update(pid)

      assert_receive %{
        symbol: "AAPL",
        current_price: _,
        last_price: _,
        price_change: _,
        price_change_percent: _,
        timestamp: _,
        volume: _
      }

      assert_receive %{
        symbol: "GOOG",
        current_price: _,
        last_price: _,
        price_change: _,
        price_change_percent: _,
        timestamp: _,
        volume: _
      }

      assert_receive %{
        symbol: "TSLA",
        current_price: _,
        last_price: _,
        price_change: _,
        price_change_percent: _,
        timestamp: _,
        volume: _
      }

      assert_receive %{
        symbol: "AMZN",
        current_price: _,
        last_price: _,
        price_change: _,
        price_change_percent: _,
        timestamp: _,
        volume: _
      }

      refute_receive _
    end

    test "broadcasts stock price only related to subscribed symbols", %{pid: pid} do
      Phoenix.PubSub.subscribe(LiveDataFeed.PubSub, "stocks:GOOG")
      Phoenix.PubSub.subscribe(LiveDataFeed.PubSub, "stocks:AMZN")

      force_stock_update(pid)

      assert_receive %{
        symbol: "GOOG",
        current_price: _,
        last_price: _,
        price_change: _,
        price_change_percent: _,
        timestamp: _,
        volume: _
      }

      assert_receive %{
        symbol: "AMZN",
        current_price: _,
        last_price: _,
        price_change: _,
        price_change_percent: _,
        timestamp: _,
        volume: _
      }

      refute_receive %{
        symbol: "TSLA",
        current_price: _,
        last_price: _,
        price_change: _,
        price_change_percent: _,
        timestamp: _,
        volume: _
      }

      refute_receive %{
        symbol: "AAPL",
        current_price: _,
        last_price: _,
        price_change: _,
        price_change_percent: _,
        timestamp: _,
        volume: _
      }
    end

    test "calls StockService.set_stocks_data/1 with current prices" do
      Mimic.expect(StockService, :set_stocks_data, fn stocks ->
        assert Enum.any?(stocks, fn
                 %{symbol: "AAPL", value: 150.0} -> true
                 _ -> false
               end)

        assert Enum.any?(stocks, fn
                 %{symbol: "TSLA", value: 700.0} -> true
                 _ -> false
               end)

        :ok
      end)

      state = %{stock_price_fetcher: MockFetcher}

      {:noreply, new_state} = PriceStreamer.handle_info(:update, state)

      assert new_state == state
    end
  end

  describe "terminate/2 graceful shutdown" do
    test "logs success when snapshot saved" do
      logs =
        capture_log(fn ->
          PriceStreamer.terminate(:normal, %{stock_price_fetcher: LiveDataFeed.LocalPriceFetcher})
        end)

      assert logs =~ "Gracefully shutting down"
      assert logs =~ "Snapshot saved successfully."
    end

    test "logs warning when snapshot fails" do
      logs =
        capture_log(fn ->
          PriceStreamer.terminate(:normal, %{stock_price_fetcher: FailingPriceFetcher})
        end)

      assert logs =~ "Gracefully shutting down"
      assert logs =~ "Snapshot could not be saved."
    end
  end

  defp force_stock_update(pid), do: send(pid, :update)
end

defmodule FailingPriceFetcher do
  def fetch_prices do
    [%{symbol: :invalid, current_price: 0}]
  end
end

defmodule MockFetcher do
  def fetch_prices do
    [
      %{symbol: "AAPL", current_price: 150.0, timestamp: 1_000, volume: 1_000},
      %{symbol: "TSLA", current_price: 700.0, timestamp: 1_000, volume: 2_000}
    ]
  end
end
