defmodule LiveDataFeed.Fixtures.StockFixtures do
  @type stock :: {atom(), String.t(), integer()}

  @spec get_stock_by_symbol(String.t()) :: {:ok, [stock]}
  def get_stock_by_symbol(symbol) do
    get_data_from_mnesia_table(:stock_prices, symbol)
  end

  @spec create_stock(String.t(), integer()) :: :ok
  def create_stock(symbol, value) do
    insert_data_into_mnesia_table({:stock_prices, symbol, value})
  end

  @spec clear_stock_prices_table :: :ok
  def clear_stock_prices_table() do
    :mnesia.clear_table(:stock_prices)
    :ok
  end

  defp get_data_from_mnesia_table(table, primary_key) do
    data_to_read = fn ->
      :mnesia.read({table, primary_key})
    end

    data_to_read
    |> :mnesia.transaction()
    |> case do
      {:atomic, data} -> {:ok, data}
      {:aborted, reason} -> {:error, reason}
    end
  end

  defp insert_data_into_mnesia_table(data) do
    transaction = fn ->
      :mnesia.write(data)
    end

    :mnesia.transaction(transaction)

    Process.sleep(10)
  end
end
