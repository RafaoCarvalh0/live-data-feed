defmodule LiveDataFeed.Behaviours.StockPriceFetcher do
  @callback fetch_prices() :: [
              %{
                symbol: String.t(),
                current_price: integer(),
                timestamp: integer(),
                volume: float()
              }
            ]
end
