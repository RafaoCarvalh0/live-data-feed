defmodule LiveDataFeed.Simulators.ClientSimulatorTest do
  use LiveDataFeed.DataCase

  import ExUnit.CaptureLog

  alias LiveDataFeed.Simulators.ClientSimulator

  @available_symbols ["AAPL", "GOOG", "TSLA", "AMZN"]

  setup do
    original_level = Logger.level()
    Logger.configure(level: :info)

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

    test "allow many clients to a same symbol" do
      {:ok, pid} = ClientSimulator.start_link("TSLA")
      assert Process.alive?(pid)

      {:ok, another_pid} = ClientSimulator.start_link("TSLA")
      assert Process.alive?(another_pid)

      assert pid != another_pid
    end

    test "returns error for invalid symbol" do
      assert {:error, :invalid_symbol} = ClientSimulator.start_link("INVALID")
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
          wait_for_process_to_finish()
        end)

      assert log =~
               ~s([PID #{inspect(pid)}] Received update from "TSLA": - %{symbol: "TSLA", price: 15000} cents)
    end

    test "ignores other messages" do
      {:ok, pid} = ClientSimulator.start_link("TSLA")

      message = %{foo: "bar"}

      send(pid, message)
      wait_for_process_to_finish()

      refute_received ^message
    end
  end

  defp wait_for_process_to_finish(), do: Process.sleep(100)
end
