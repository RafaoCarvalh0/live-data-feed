defmodule LiveDataFeed.Simulators.StockPriceSimulator do
  @symbols ["AAPL", "GOOG", "TSLA", "AMZN"]

  @initial_prices_in_cents %{
    "AAPL" => 15_000,
    "GOOG" => 280_000,
    "TSLA" => 70_000,
    "AMZN" => 135_000
  }

  @variation_percent 0.05

  @type available_symbols :: String.t()

  def available_symbols(), do: @symbols

  @doc """
  Returns a map of all available symbols to their current prices with random variation applied.
  Each symbol's price is based on the initial price plus a small random variation.
  """
  @spec get_prices_with_variation() :: %{String.t() => integer()}
  def get_prices_with_variation do
    Enum.reduce(@symbols, %{}, fn symbol, acc ->
      base_price = Map.get(@initial_prices_in_cents, symbol)
      new_price = apply_random_variation(base_price)
      Map.put(acc, symbol, new_price)
    end)
  end

  defp apply_random_variation(price) do
    max_variation = round(price * @variation_percent)
    variation = :rand.uniform(max_variation * 2 + 1) - max_variation - 1
    max(price + variation, 1)
  end
end
