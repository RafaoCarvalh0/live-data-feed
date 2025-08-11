defmodule LiveDataFeed.Simulators.ClientSimulatorTest do
  use ExUnit.Case, async: true
  use Mimic

  import ExUnit.CaptureLog

  alias LiveDataFeed.Simulators.ClientSimulator

  setup :verify_on_exit!

  setup do
    Application.put_env(:live_data_feed, ClientSimulator,
      stock_price_fetcher: LiveDataFeed.LocalPriceFetcher
    )

    Mimic.stub(Phoenix.PubSub, :subscribe, fn _pubsub, _topic -> :ok end)
    Mimic.stub(Phoenix.PubSub, :unsubscribe, fn _pubsub, _topic -> :ok end)

    original_level = Logger.level()
    Logger.configure(level: :info)

    on_exit(fn ->
      Logger.configure(level: original_level)
    end)

    :ok
  end

  describe "start_link/1" do
    test "starts the GenServer with given name" do
      {:ok, pid} = ClientSimulator.start_link(name: :test_client)
      assert is_pid(pid)

      state = :sys.get_state(pid)
      assert state.name == :test_client
      assert MapSet.new() == state.subscriptions
    end
  end

  describe "subscribe_to_symbol/2" do
    test "subscribes successfully when symbol is valid" do
      {:ok, pid} = ClientSimulator.start_link(name: :client1)
      assert :ok == ClientSimulator.subscribe_to_symbol(pid, "AAPL")
    end

    test "returns error when symbol is invalid" do
      {:ok, pid} = ClientSimulator.start_link(name: :client1)
      assert {:error, :invalid_symbol} == ClientSimulator.subscribe_to_symbol(pid, "INVALID")
    end
  end

  describe "unsubscribe_from_symbol/2" do
    test "unsubscribes successfully when symbol is valid" do
      {:ok, pid} = ClientSimulator.start_link(name: :client1)
      assert :ok == ClientSimulator.unsubscribe_from_symbol(pid, "GOOG")
    end

    test "returns error when symbol is invalid" do
      {:ok, pid} = ClientSimulator.start_link(name: :client1)
      assert {:error, :invalid_symbol} == ClientSimulator.unsubscribe_from_symbol(pid, "INVALID")
    end
  end

  describe "handle_call :subscribe" do
    test "updates state and subscribes to pubsub topic" do
      {:ok, pid} = ClientSimulator.start_link(name: :client1)
      assert :ok == GenServer.call(pid, {:subscribe, "AAPL"})

      state = :sys.get_state(pid)
      assert MapSet.member?(state.subscriptions, "AAPL")
    end
  end

  describe "handle_call :unsubscribe" do
    test "updates state and unsubscribes from pubsub topic" do
      {:ok, pid} = ClientSimulator.start_link(name: :client1)
      GenServer.call(pid, {:subscribe, "GOOG"})

      assert :ok == GenServer.call(pid, {:unsubscribe, "GOOG"})

      state = :sys.get_state(pid)
      refute MapSet.member?(state.subscriptions, "GOOG")
    end
  end

  describe "handle_info/2" do
    test "handles stock update message and other messages keeping state" do
      {:ok, pid} = ClientSimulator.start_link(name: :client1)

      msg = %{symbol: "AAPL", price: 100}

      {:noreply, state} = ClientSimulator.handle_info(msg, :sys.get_state(pid))
      assert state

      {:noreply, state2} = ClientSimulator.handle_info(:random_message, state)
      assert state == state2
    end
  end

  describe "terminate/2" do
    test "calls ClientRegistry.remove_client/1 and logs a warning" do
      {:ok, pid} = ClientSimulator.start_link(name: :client_foo)

      logs =
        capture_log(fn ->
          GenServer.stop(pid)
        end)

      assert logs =~ ~s(Gracefully shutting down: clearing :client_foo data from cache. reason:)

      refute Process.alive?(pid)
    end
  end
end
