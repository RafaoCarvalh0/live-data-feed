defmodule LiveDataFeed.ClientSimulatorTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias LiveDataFeed.ClientSimulator

  @available_symbols ["AAPL", "GOOG", "TSLA", "AMZN"]

  setup do
    original_level = Logger.level()
    Logger.configure(level: :info)

    {:ok, _} = start_supervised({Registry, keys: :unique, name: LiveDataFeed.ClientRegistry})

    on_exit(fn ->
      Logger.configure(level: original_level)
    end)
  end

  describe "start_link/1" do
    test "starts client process with valid symbol" do
      Enum.each(@available_symbols, fn symbol ->
        {:ok, pid} = ClientSimulator.start_link(symbol)
        assert Process.alive?(pid)
      end)
    end

    test "returns error for invalid symbol" do
      assert {:error, :invalid_symbol} = ClientSimulator.start_link("INVALID")
    end

    test "returns error if a client is already using a symbol" do
      {:ok, pid} = ClientSimulator.start_link("TSLA")
      assert Process.alive?(pid)

      assert {:error, {:already_started, ^pid}} = ClientSimulator.start_link("TSLA")
    end
  end

  describe "init/1" do
    test "subscribes client to the correct PubSub topic and logs subscription message" do
      log =
        capture_log(fn ->
          {:ok, _pid} = ClientSimulator.start_link("GOOG")
        end)

      assert log =~ ~S(Subscribed to "stocks:GOOG")
    end
  end

  describe "handle_info/2" do
    test "receives stock price update message and logs update" do
      {:ok, pid} = ClientSimulator.start_link("TSLA")

      log =
        capture_log(fn ->
          send(pid, %{symbol: "TSLA", price: 15000})
          Process.sleep(10)
        end)

      assert log =~ ~S(ClientSimulator "TSLA")
      assert log =~ ~S(Received update: 15000 cents)
    end

    test "ignores other messages" do
      {:ok, pid} = ClientSimulator.start_link("TSLA")

      message = %{foo: "bar"}

      send(pid, message)
      Process.sleep(10)

      refute_received message
    end
  end
end
