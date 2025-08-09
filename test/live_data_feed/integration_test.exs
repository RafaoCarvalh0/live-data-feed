defmodule LiveDataFeed.IntegrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias LiveDataFeed.{PriceStreamer, ClientSimulator}

  @price_streamer_process :price_streamer_test

  setup do
    {:ok, price_streamer_pid} = start_supervised({PriceStreamer, name: @price_streamer_process})

    original_level = Logger.level()
    Logger.configure(level: :info)

    on_exit(fn ->
      Logger.configure(level: original_level)
    end)

    %{price_streamer_pid: price_streamer_pid}
  end

  test "clients receive only their subscribed stock updates", %{price_streamer_pid: ps_pid} do
    {:ok, client_aapl} = ClientSimulator.start_link("AAPL")
    {:ok, client_aapl_amzn_1} = ClientSimulator.start_link("AAPL")
    {:ok, client_aapl_amzn_2} = ClientSimulator.start_link("AMZN")
    {:ok, client_aapl_amzn_tsla_1} = ClientSimulator.start_link("AAPL")
    {:ok, client_aapl_amzn_tsla_2} = ClientSimulator.start_link("AMZN")
    {:ok, client_aapl_amzn_tsla_3} = ClientSimulator.start_link("TSLA")

    log =
      capture_log(fn ->
        force_stock_update(ps_pid)
      end)

    assert log =~ ~s([PID #{inspect(client_aapl)}] Received update: "AAPL")
    assert log =~ ~s([PID #{inspect(client_aapl_amzn_1)}] Received update: "AAPL")
    assert log =~ ~s([PID #{inspect(client_aapl_amzn_2)}] Received update: "AMZN")

    assert log =~ ~s([PID #{inspect(client_aapl_amzn_tsla_1)}] Received update: "AAPL")
    assert log =~ ~s([PID #{inspect(client_aapl_amzn_tsla_2)}] Received update: "AMZN")
    assert log =~ ~s([PID #{inspect(client_aapl_amzn_tsla_3)}] Received update: "TSLA")

    refute log =~ ~s([PID #{inspect(client_aapl)}] Received update: "GOOG")
    refute log =~ ~s([PID #{inspect(client_aapl_amzn_1)}] Received update: "TSLA")
    refute log =~ ~s([PID #{inspect(client_aapl_amzn_2)}] Received update: "TSLA")
  end

  test "clients processes stays alive while price streamer is down, and price streamer can recover itself",
       %{price_streamer_pid: price_streamer_pid} do
    {:ok, client} = ClientSimulator.start_link("AAPL")
    {:ok, client2} = ClientSimulator.start_link("GOOG")
    {:ok, client3} = ClientSimulator.start_link("TSLA")

    price_streamer_monitor = Process.monitor(price_streamer_pid)

    Process.exit(price_streamer_pid, :kill)
    assert_receive {:DOWN, ^price_streamer_monitor, :process, ^price_streamer_pid, _reason}, 1_000

    assert Process.alive?(client)
    assert Process.alive?(client2)
    assert Process.alive?(client3)

    new_pid = wait_for_new_price_streamer(price_streamer_pid)
    assert is_pid(new_pid)
    assert new_pid != price_streamer_pid
  end

  defp force_stock_update(price_streamer_pid) do
    send(price_streamer_pid, :update)
    Process.sleep(100)
  end

  defp wait_for_new_price_streamer(old_pid, attempts \\ 10) do
    case Process.whereis(@price_streamer_process) do
      nil ->
        if attempts > 0 do
          Process.sleep(100)
          wait_for_new_price_streamer(old_pid, attempts - 1)
        else
          nil
        end

      new_pid when new_pid != old_pid ->
        new_pid

      _ ->
        if attempts > 0 do
          Process.sleep(100)
          wait_for_new_price_streamer(old_pid, attempts - 1)
        else
          nil
        end
    end
  end
end
