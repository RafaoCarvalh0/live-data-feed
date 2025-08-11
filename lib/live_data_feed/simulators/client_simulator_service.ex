defmodule LiveDataFeed.Simulators.ClientSimulatorService do
  @moduledoc """
  Manages client simulators lifecycle and subscriptions.

  Provides functions to start clients, subscribe/unsubscribe to stock symbols,
  list active clients, and remove clients.
  """

  alias LiveDataFeed.Simulators.ClientSimulator
  alias LiveDataFeed.Simulators.ClientRegistry

  @spec subscribe_to_symbol(atom(), String.t()) ::
          :ok | {:error, :client_simulator_not_running | :invalid_symbol}
  def subscribe_to_symbol(client_name, symbol) when is_atom(client_name) do
    with pid when is_pid(pid) <- ClientRegistry.get_client(client_name),
         true <- valid_symbol?(symbol) do
      ClientSimulator.subscribe_to_symbol(pid, symbol)
    else
      nil -> {:error, :client_simulator_not_running}
      false -> {:error, :invalid_symbol}
    end
  end

  @spec unsubscribe_from_symbol(atom(), String.t()) ::
          :ok | {:error, :client_simulator_not_running | :invalid_symbol}
  def unsubscribe_from_symbol(client_name, symbol) when is_atom(client_name) do
    with pid when is_pid(pid) <- ClientRegistry.get_client(client_name),
         true <- valid_symbol?(symbol) do
      ClientSimulator.unsubscribe_from_symbol(pid, symbol)
    else
      nil -> {:error, :client_simulator_not_running}
      false -> {:error, :invalid_symbol}
    end
  end

  @spec start_client(atom()) :: {:ok, pid()} | {:error, term()}
  def start_client(name) when is_atom(name) do
    spec = {LiveDataFeed.Simulators.ClientSimulator, name: name}

    case DynamicSupervisor.start_child(LiveDataFeed.Simulators.ClientSupervisor, spec) do
      {:ok, pid} ->
        ClientRegistry.add_client(name, pid)
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec start_client(any()) :: {:error, String.t()}
  def start_client(_), do: {:error, "name must be an atom"}

  @spec list_clients() :: %{optional(atom()) => pid()}
  def list_clients() do
    ClientRegistry.list_clients()
  end

  @spec remove_client(atom()) :: :ok | {:error, :client_not_found}
  def remove_client(name) when is_atom(name) do
    case ClientRegistry.get_client(name) do
      nil ->
        {:error, :client_not_found}

      pid ->
        Process.exit(pid, :normal)
        ClientRegistry.remove_client(name)
        :ok
    end
  end

  @spec valid_symbol?(any()) :: boolean()
  defp valid_symbol?(symbol) when is_binary(symbol) do
    symbol in price_fetcher().available_symbols()
  end

  defp valid_symbol?(_), do: false

  defp price_fetcher() do
    Application.get_env(:live_data_feed, __MODULE__, %{})[:stock_price_fetcher] ||
      LiveDataFeed.LocalPriceFetcher
  end
end
