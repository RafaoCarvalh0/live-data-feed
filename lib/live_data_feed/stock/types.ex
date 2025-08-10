defmodule LiveDataFeed.Stock.Types do
  @type stock :: %{
          symbol: String.t(),
          price: integer()
        }

  @type register_stocks_input :: [stock()]
end
