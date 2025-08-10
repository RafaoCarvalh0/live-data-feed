defmodule LiveDataFeed.LocalPriceFetcher do
  @behaviour LiveDataFeed.Behaviours.StockPriceFetcher

  alias LiveDataFeed.Simulators.StockPriceSimulator

  @impl true
  def fetch_prices() do
    StockPriceSimulator.get_prices_with_variation()
  end
end
