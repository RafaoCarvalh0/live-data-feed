defmodule LiveDataFeed.Simulators.StockPriceSimulatorTest do
  use ExUnit.Case, async: false

  alias LiveDataFeed.Simulators.StockPriceSimulator

  @tolerance 0.05

  @initial_prices_in_cents %{
    "AAPL" => 15_000,
    "GOOG" => 280_000,
    "TSLA" => 70_000,
    "AMZN" => 135_000
  }

  @symbols ["AAPL", "GOOG", "TSLA", "AMZN"]

  describe "get_prices_with_variation/0" do
    test "returns all symbols" do
      prices = StockPriceSimulator.get_prices_with_variation()
      symbols = Enum.map(prices, & &1.symbol)

      assert Enum.sort(symbols) == Enum.sort(@symbols)
    end

    test "prices vary within 5% of initial price" do
      prices = StockPriceSimulator.get_prices_with_variation()

      Enum.each(prices, fn %{symbol: symbol, current_price: price_cents} ->
        initial_cents = Map.fetch!(@initial_prices_in_cents, symbol)
        initial_price = initial_cents / 100.0

        current_price = price_cents / 100.0

        max_variation = initial_price * @tolerance
        diff = abs(current_price - initial_price)

        assert diff <= max_variation,
               "Price variation for #{symbol} (#{current_price}) exceeds tolerance from initial (#{initial_price})"
      end)
    end

    test "timestamp is a non-negative integer" do
      prices = StockPriceSimulator.get_prices_with_variation()

      Enum.each(prices, fn %{timestamp: ts} ->
        assert is_integer(ts)
        assert ts >= 0
      end)
    end

    test "volume is a positive float with up to 4 decimal places" do
      prices = StockPriceSimulator.get_prices_with_variation()

      Enum.each(prices, fn %{volume: vol} ->
        assert is_float(vol)
        assert vol >= 0

        str = :io_lib.format("~.4f", [vol]) |> to_string()

        [_int_part, decimal_part] = String.split(str, ".")

        assert String.length(decimal_part) == 4
      end)
    end

    test "each price map has the required keys" do
      prices = StockPriceSimulator.get_prices_with_variation()

      Enum.each(prices, fn price_map ->
        assert Map.has_key?(price_map, :symbol)
        assert Map.has_key?(price_map, :current_price)
        assert Map.has_key?(price_map, :timestamp)
        assert Map.has_key?(price_map, :volume)
      end)
    end
  end
end
