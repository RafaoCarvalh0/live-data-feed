defmodule LiveDataFeed.Simulators.ClientRegistryTest do
  use ExUnit.Case, async: false

  alias LiveDataFeed.Simulators.ClientRegistry

  describe "add_client/2" do
    test "adds a client with a valid name and pid" do
      name = :client1
      pid = self()

      assert :ok = ClientRegistry.add_client(name, pid)
      assert ClientRegistry.get_client(name) == pid
    end
  end

  describe "get_client/1" do
    test "returns the pid of the client when it exists" do
      name = :client1
      pid = self()
      ClientRegistry.add_client(name, pid)

      assert ClientRegistry.get_client(name) == pid
    end

    test "returns nil when the client does not exist" do
      assert ClientRegistry.get_client(:unknown) == nil
    end
  end

  describe "list_clients/0" do
    test "returns all registered clients" do
      ClientRegistry.add_client(:client1, self())
      ClientRegistry.add_client(:client2, self())

      clients = ClientRegistry.list_clients()
      assert is_map(clients)
      assert Map.has_key?(clients, :client1)
      assert Map.has_key?(clients, :client2)
    end
  end

  describe "remove_client/1" do
    test "removes an existing client" do
      name = :client1
      pid = self()
      ClientRegistry.add_client(name, pid)

      ClientRegistry.remove_client(name)
      assert ClientRegistry.get_client(name) == nil
    end
  end
end
