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

  defp force_stock_update(pid) do
    send(pid, :update)
    Process.sleep(100)
  end
end
