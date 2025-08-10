defmodule LiveDataFeed.LocalPriceFetcher do
  @behaviour LiveDataFeed.StockPriceFetcher

  alias LiveDataFeed.Simulators.StockPriceSimulator

  @impl true
  def fetch_prices() do
    StockPriceSimulator.get_prices_with_variation()
  end

  @impl true
  def available_symbols() do
    StockPriceSimulator.available_symbols()
  end
end
