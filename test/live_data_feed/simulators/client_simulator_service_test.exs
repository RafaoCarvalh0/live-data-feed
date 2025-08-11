defmodule LiveDataFeed.Simulators.ClientSimulatorServiceTest do
  use ExUnit.Case, async: true
  use Mimic

  alias LiveDataFeed.Simulators.ClientSimulatorService
  alias LiveDataFeed.Simulators.ClientRegistry

  setup :verify_on_exit!

  describe "subscribe_to_symbol/2" do
    test "subscribes when client running and symbol valid" do
      expect(LiveDataFeed.Simulators.ClientRegistry, :get_client, fn :client1 -> self() end)
      expect(LiveDataFeed.LocalPriceFetcher, :available_symbols, fn -> ["AAPL", "GOOG"] end)

      expect(LiveDataFeed.Simulators.ClientSimulator, :subscribe_to_symbol, fn pid, "AAPL" ->
        assert pid == self()
        :ok
      end)

      assert :ok == ClientSimulatorService.subscribe_to_symbol(:client1, "AAPL")
    end

    test "returns error if client simulator not running" do
      expect(LiveDataFeed.Simulators.ClientRegistry, :get_client, fn :unknown -> nil end)

      assert {:error, :client_simulator_not_running} ==
               ClientSimulatorService.subscribe_to_symbol(:unknown, "AAPL")
    end

    test "returns error if invalid symbol" do
      expect(LiveDataFeed.Simulators.ClientRegistry, :get_client, fn :client1 -> self() end)
      expect(LiveDataFeed.LocalPriceFetcher, :available_symbols, fn -> ["AAPL", "GOOG"] end)

      assert {:error, :invalid_symbol} ==
               ClientSimulatorService.subscribe_to_symbol(:client1, "INVALID")
    end
  end

  describe "unsubscribe_from_symbol/2" do
    test "unsubscribes when client running and symbol valid" do
      expect(LiveDataFeed.Simulators.ClientRegistry, :get_client, fn :client1 -> self() end)
      expect(LiveDataFeed.LocalPriceFetcher, :available_symbols, fn -> ["AAPL", "GOOG"] end)

      expect(LiveDataFeed.Simulators.ClientSimulator, :unsubscribe_from_symbol, fn pid, "AAPL" ->
        assert pid == self()
        :ok
      end)

      assert :ok == ClientSimulatorService.unsubscribe_from_symbol(:client1, "AAPL")
    end

    test "returns error if client simulator not running" do
      expect(LiveDataFeed.Simulators.ClientRegistry, :get_client, fn :unknown -> nil end)

      assert {:error, :client_simulator_not_running} ==
               ClientSimulatorService.unsubscribe_from_symbol(:unknown, "AAPL")
    end

    test "returns error if invalid symbol" do
      expect(LiveDataFeed.Simulators.ClientRegistry, :get_client, fn :client1 -> self() end)
      expect(LiveDataFeed.LocalPriceFetcher, :available_symbols, fn -> ["AAPL", "GOOG"] end)

      assert {:error, :invalid_symbol} ==
               ClientSimulatorService.unsubscribe_from_symbol(:client1, "INVALID")
    end
  end

  describe "start_client/1" do
    setup do
      Agent.update(ClientRegistry, fn _ -> %{} end)
      :ok
    end

    test "starts new client and adds to registry" do
      {:ok, pid} = ClientSimulatorService.start_client(:client_test)
      assert is_pid(pid)
      assert ClientRegistry.get_client(:client_test) == pid
      assert :ok = ClientSimulatorService.remove_client(:client_test)
    end

    test "returns error for invalid name" do
      assert {:error, "name must be an atom"} = ClientSimulatorService.start_client("not_atom")
    end
  end

  describe "list_clients/0" do
    test "delegates to ClientRegistry.list_clients" do
      expect(LiveDataFeed.Simulators.ClientRegistry, :list_clients, fn -> %{a: self()} end)

      assert %{a: pid} = ClientSimulatorService.list_clients()
      assert is_pid(pid)
    end
  end

  describe "remove_client/1" do
    test "removes existing client" do
      pid =
        spawn(fn ->
          Process.flag(:trap_exit, true)

          receive do
            :stop -> :ok
          after
            5_000 -> :ok
          end
        end)

      Process.register(pid, :client2)

      Mimic.expect(ClientRegistry, :remove_client, fn :client2 -> :ok end)

      Mimic.expect(
        DynamicSupervisor,
        :terminate_child,
        fn LiveDataFeed.Simulators.ClientSupervisor, ^pid ->
          Process.exit(pid, :normal)
          :ok
        end
      )

      monitor_ref = Process.monitor(pid)

      assert :ok = ClientSimulatorService.remove_client(:client2)

      assert_receive {:DOWN, ^monitor_ref, :process, ^pid, _reason}, 5_000
    end

    test "returns error if client is not found" do
      assert {:error, :client_not_found} == ClientSimulatorService.remove_client(:non_existent)
    end
  end
end
