defmodule LiveDataFeed.Simulators.StockPriceSimulator do
  @moduledoc """
  Simulates fluctuating stock prices and trading volumes for a fixed set of symbols.

  Provides a list of stock price data with random variations applied to
  initial prices to mimic real-time market changes. Each price entry includes
  the symbol, current price in cents, timestamp, and simulated volume.
  """

  @symbols ["AAPL", "GOOG", "TSLA", "AMZN"]

  @initial_prices_in_cents %{
    "AAPL" => 15_000,
    "GOOG" => 280_000,
    "TSLA" => 70_000,
    "AMZN" => 135_000
  }

  @variation_percent 0.05

  def available_symbols, do: @symbols

  @doc """
  Returns a list of stock price maps.

  The prices and volumes returned are simulated with random variations around initial values,
  intended to mimic real-time fluctuating stock data.
  """
  @spec get_prices_with_variation() :: [
          %{
            symbol: String.t(),
            current_price: integer(),
            timestamp: integer(),
            volume: float()
          }
        ]
  def get_prices_with_variation() do
    Enum.map(@symbols, fn symbol ->
      base_price_cents = Map.get(@initial_prices_in_cents, symbol)
      current_price = apply_random_variation(base_price_cents) / 100.0

      current_price_cents = round(current_price * 100)

      %{
        symbol: symbol,
        current_price: current_price_cents,
        timestamp: System.system_time(:millisecond),
        volume: simulate_volume()
      }
    end)
  end

  defp apply_random_variation(price_cents) do
    max_variation = round(price_cents * @variation_percent)
    variation = :rand.uniform(max_variation * 2 + 1) - max_variation - 1
    max(price_cents + variation, 1)
  end

  defp simulate_volume do
    (:rand.uniform() * 10_000)
    |> Float.round(4)
  end
end
