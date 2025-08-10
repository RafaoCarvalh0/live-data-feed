defmodule LiveDataFeed.Stock.Types do
  @type stock :: %{
          symbol: String.t(),
          current_price: integer(),
          timestamp: integer(),
          volume: float()
        }

  @type register_stocks_input :: [stock()]
end
