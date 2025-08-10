defmodule LiveDataFeed.Stock.StockRespository do
  def upsert_stock(symbol, value) do
    transaction = fn ->
      :mnesia.write({:stock_prices, symbol, value})
    end

    transaction
    |> :mnesia.transaction()
    |> case do
      {:atomic, :ok} -> :ok
      {:aborted, reason} -> {:error, reason}
    end
  end

  def get_stocks_by_symbols(symbols) do
    data_to_read = fn ->
      Enum.map(symbols, fn symbol -> :mnesia.read({:stock_prices, symbol}) end)
    end

    data_to_read
    |> :mnesia.transaction()
    |> case do
      {:atomic, data} -> {:ok, data}
      {:aborted, reason} -> {:error, reason}
    end
  end
end
