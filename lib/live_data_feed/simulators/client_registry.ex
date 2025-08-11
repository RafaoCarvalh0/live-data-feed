defmodule LiveDataFeed.Simulators.ClientRegistry do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_client(name, pid) when is_atom(name) and is_pid(pid) do
    Agent.update(__MODULE__, fn clients ->
      Map.put(clients, name, pid)
    end)
  end

  def get_client(name) when is_atom(name) do
    Agent.get(__MODULE__, fn clients ->
      Map.get(clients, name)
    end)
  end

  def list_clients do
    Agent.get(__MODULE__, & &1)
  end

  def remove_client(name) when is_atom(name) do
    Agent.update(__MODULE__, fn clients ->
      Map.delete(clients, name)
    end)
  end
end
