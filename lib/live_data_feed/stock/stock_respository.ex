defmodule LiveDataFeed.Stock.StockRespository do
  alias LiveDataFeed.Stock.Types

  @spec upsert_stocks(Types.register_stocks_input()) :: :ok | {:error, any()}
  def upsert_stocks(attrs) do
    transaction = fn ->
      Enum.map(attrs, fn stock ->
        :mnesia.write({:stock_prices, stock.symbol, stock.price})
      end)
    end

    transaction
    |> :mnesia.transaction()
    |> case do
      {:atomic, _} -> :ok
      {:aborted, reason} -> {:error, reason}
    end
  end

  @spec get_stocks_by_symbols([String.t()]) ::
          {:ok, [%{symbol: String.t(), price: integer()}]} | {:error, any()}
  def get_stocks_by_symbols(symbols) do
    data_to_read = fn ->
      Enum.map(symbols, fn symbol -> :mnesia.read({:stock_prices, symbol}) end)
    end

    data_to_read
    |> :mnesia.transaction()
    |> case do
      {:atomic, data} ->
        data
        |> List.flatten()
        |> Enum.map(fn {_, symbol, price} -> %{symbol: symbol, price: price} end)
        |> then(&{:ok, &1})

      {:aborted, reason} ->
        {:error, reason}
    end
  end
end
