defmodule LiveDataFeed.Stock.StockService do
  alias LiveDataFeed.Stock.Types
  alias LiveDataFeed.Stock.StockRespository

  require Logger

  @spec get_stocks_data :: [Types.stock()]
  def get_stocks_data() do
    stock_price_fetcher =
      Application.get_env(:stock_price_fetcher, :price_fetcher, LiveDataFeed.LocalPriceFetcher)

    stock_price_fetcher.available_symbols()
    |> StockRespository.get_stocks_by_symbols()
    |> case do
      {:ok, data} ->
        data

      {:error, reason} ->
        Logger.error("Error while fetching stocks data. reason: #{inspect(reason)}")
        {:error, :failed_to_fetch_stocks}
    end
  end

  @spec register_stocks(Types.register_stocks_input()) :: :ok | {:error, atom()}
  def register_stocks(stock_list) do
    case validate_stocks_input(stock_list) do
      :valid ->
        stock_list
        |> StockRespository.upsert_stocks()
        |> case do
          :ok ->
            :ok

          {:error, reason} ->
            Logger.error("Error while registering stocks. reason: #{inspect(reason)}")
            {:error, :failed_to_register_stocks}
        end

      error ->
        Logger.error(
          "Error while registering stocks. reason: #{inspect(error)}, #{inspect(stock_list)}"
        )

        {:error, :invalid_stock_input}
    end
  end

  defp validate_stocks_input(stocks) do
    Enum.reduce_while(stocks, :valid, fn stock, acc ->
      sorted_keys =
        stock
        |> Map.keys()
        |> Enum.sort()

      if sorted_keys == [:price, :symbol] &&
           is_binary(stock.symbol) &&
           is_integer(stock.price) do
        {:cont, acc}
      else
        {:halt, :invalid}
      end
    end)
  end
end
