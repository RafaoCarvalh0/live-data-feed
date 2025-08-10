defmodule LiveDataFeed.Stock.StockService do
  alias LiveDataFeed.Stock.Types

  # TODO: implement mnesia and use it as a db
  @spec get_stocks_latest_data :: [Types.stock()]
  def get_stocks_latest_data() do
    [nil]
  end

  @spec register_stocks(Types.register_stocks_input()) :: :ok | {:error, atom()}
  def register_stocks(stock_list) do
    nil
  end
end
