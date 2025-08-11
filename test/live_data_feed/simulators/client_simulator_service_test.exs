defmodule LiveDataFeed.Simulators.ClientSimulatorServiceTest do
  use ExUnit.Case, async: true
  use Mimic

  alias LiveDataFeed.Simulators.ClientSimulatorService

  setup :verify_on_exit!

  describe "subscribe_to_symbol/2" do
    test "subscribes when client running and symbol valid" do
      Mimic.expect(LiveDataFeed.Simulators.ClientRegistry, :get_client, fn :client1 -> self() end)
      Mimic.expect(LiveDataFeed.LocalPriceFetcher, :available_symbols, fn -> ["AAPL", "GOOG"] end)

      Mimic.expect(LiveDataFeed.Simulators.ClientSimulator, :subscribe_to_symbol, fn pid,
                                                                                     "AAPL" ->
        assert pid == self()
        :ok
      end)

      assert :ok == ClientSimulatorService.subscribe_to_symbol(:client1, "AAPL")
    end

    test "returns error if client simulator not running" do
      Mimic.expect(LiveDataFeed.Simulators.ClientRegistry, :get_client, fn :unknown -> nil end)

      assert {:error, :client_simulator_not_running} ==
               ClientSimulatorService.subscribe_to_symbol(:unknown, "AAPL")
    end

    test "returns error if invalid symbol" do
      Mimic.expect(LiveDataFeed.Simulators.ClientRegistry, :get_client, fn :client1 -> self() end)
      Mimic.expect(LiveDataFeed.LocalPriceFetcher, :available_symbols, fn -> ["AAPL", "GOOG"] end)

      assert {:error, :invalid_symbol} ==
               ClientSimulatorService.subscribe_to_symbol(:client1, "INVALID")
    end
  end

  describe "unsubscribe_from_symbol/2" do
    test "unsubscribes when client running and symbol valid" do
      Mimic.expect(LiveDataFeed.Simulators.ClientRegistry, :get_client, fn :client1 -> self() end)
      Mimic.expect(LiveDataFeed.LocalPriceFetcher, :available_symbols, fn -> ["AAPL", "GOOG"] end)

      Mimic.expect(LiveDataFeed.Simulators.ClientSimulator, :unsubscribe_from_symbol, fn pid,
                                                                                         "AAPL" ->
        assert pid == self()
        :ok
      end)

      assert :ok == ClientSimulatorService.unsubscribe_from_symbol(:client1, "AAPL")
    end

    test "returns error if client simulator not running" do
      Mimic.expect(LiveDataFeed.Simulators.ClientRegistry, :get_client, fn :unknown -> nil end)

      assert {:error, :client_simulator_not_running} ==
               ClientSimulatorService.unsubscribe_from_symbol(:unknown, "AAPL")
    end

    test "returns error if invalid symbol" do
      Mimic.expect(LiveDataFeed.Simulators.ClientRegistry, :get_client, fn :client1 -> self() end)
      Mimic.expect(LiveDataFeed.LocalPriceFetcher, :available_symbols, fn -> ["AAPL", "GOOG"] end)

      assert {:error, :invalid_symbol} ==
               ClientSimulatorService.unsubscribe_from_symbol(:client1, "INVALID")
    end
  end

  describe "start_client/1" do
    test "starts new client and adds to registry" do
      Mimic.expect(LiveDataFeed.Simulators.ClientSimulator, :start_link, fn name: :client1 ->
        {:ok, self()}
      end)

      Mimic.expect(LiveDataFeed.Simulators.ClientRegistry, :add_client, fn :client1, pid ->
        assert pid == self()
        :ok
      end)

      assert {:ok, pid} = ClientSimulatorService.start_client(:client1)
      assert pid == self()
    end

    test "returns existing pid if already started" do
      Mimic.expect(LiveDataFeed.Simulators.ClientSimulator, :start_link, fn name: :client1 ->
        {:error, {:already_started, self()}}
      end)

      assert {:ok, pid} = ClientSimulatorService.start_client(:client1)
      assert pid == self()
    end

    test "returns error for invalid name" do
      assert {:error, "name must be an atom"} = ClientSimulatorService.start_client("not_atom")
    end
  end

  describe "list_clients/0" do
    test "delegates to ClientRegistry.list_clients" do
      Mimic.expect(LiveDataFeed.Simulators.ClientRegistry, :list_clients, fn -> %{a: self()} end)

      assert %{a: pid} = ClientSimulatorService.list_clients()
      assert is_pid(pid)
    end
  end

  describe "remove_client/1" do
    setup do
      dummy_pid = spawn(fn -> Process.sleep(:infinity) end)

      %{dummy_pid: dummy_pid}
    end

    test "removes existing client" do
      dummy_pid =
        spawn(fn ->
          Process.flag(:trap_exit, true)

          receive do
            :stop -> :ok
            {:EXIT, _from, _reason} -> :ok
          after
            5_000 -> :ok
          end
        end)

      Mimic.expect(LiveDataFeed.Simulators.ClientRegistry, :get_client, fn :client1 ->
        dummy_pid
      end)

      Mimic.expect(LiveDataFeed.Simulators.ClientRegistry, :remove_client, fn :client1 -> :ok end)

      monitor_ref = Process.monitor(dummy_pid)

      assert :ok = ClientSimulatorService.remove_client(:client1)

      assert_receive {:DOWN, ^monitor_ref, :process, ^dummy_pid, _reason}, 1_000
    end

    test "returns error if client not found" do
      Mimic.expect(LiveDataFeed.Simulators.ClientRegistry, :get_client, fn :client1 -> nil end)
      assert {:error, :client_not_found} == ClientSimulatorService.remove_client(:client1)
    end
  end
end
