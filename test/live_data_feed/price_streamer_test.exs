defmodule LiveDataFeed.PriceStreamerTest do
  use ExUnit.Case, async: false

  alias LiveDataFeed.PriceStreamer

  @symbols ["AAPL", "GOOG", "TSLA", "AMZN"]

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

      assert_receive %{symbol: "AAPL", price: _}
      assert_receive %{symbol: "GOOG", price: _}
      assert_receive %{symbol: "TSLA", price: _}
      assert_receive %{symbol: "AMZN", price: _}

      refute_receive _
    end

    test "broadcasts stock price only related to subscribed symbols", %{pid: pid} do
      Phoenix.PubSub.subscribe(LiveDataFeed.PubSub, "stocks:GOOG")
      Phoenix.PubSub.subscribe(LiveDataFeed.PubSub, "stocks:AMZN")

      force_stock_update(pid)

      assert_receive %{symbol: "GOOG", price: _}
      assert_receive %{symbol: "AMZN", price: _}

      refute_receive %{symbol: "TSLA", price: _}
      refute_receive %{symbol: "AAPL", price: _}
    end
  end

  defp force_stock_update(pid), do: send(pid, :update)
end
