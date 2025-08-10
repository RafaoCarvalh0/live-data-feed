defmodule LiveDataFeed.Simulators.StockPriceSimulatorTest do
  use ExUnit.Case

  alias LiveDataFeed.Simulators.StockPriceSimulator

  describe "available_symbols/0" do
    test "returns all symbols as strings" do
      assert StockPriceSimulator.available_symbols() == ["AAPL", "GOOG", "TSLA", "AMZN"]
    end
  end

  describe "get_prices_with_variation/0" do
    test "returns a map with all symbols as string keys" do
      prices = StockPriceSimulator.get_prices_with_variation()

      assert prices
             |> Map.keys()
             |> Enum.sort() == ["AAPL", "AMZN", "GOOG", "TSLA"]
    end

    test "prices are integers and close to initial values" do
      prices = StockPriceSimulator.get_prices_with_variation()

      initial = %{
        "AAPL" => 15_000,
        "GOOG" => 280_000,
        "TSLA" => 70_000,
        "AMZN" => 135_000
      }

      Enum.each(StockPriceSimulator.available_symbols(), fn symbol ->
        price = prices[symbol]
        base = initial[symbol]

        assert is_integer(price)
        max_variation = round(base * 0.05)

        assert price >= base - max_variation
        assert price <= base + max_variation
      end)
    end

    test "prices are never below 1" do
      Enum.each(1..20, fn _ ->
        prices = StockPriceSimulator.get_prices_with_variation()

        for {_symbol, price} <- prices do
          assert price >= 1
        end
      end)
    end
  end
end
