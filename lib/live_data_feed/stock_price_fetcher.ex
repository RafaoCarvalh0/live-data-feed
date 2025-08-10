defmodule LiveDataFeed.StockPriceFetcher do
  @callback fetch_prices() :: %{String.t() => integer()}

  @callback available_symbols() :: [String.t()]
end
