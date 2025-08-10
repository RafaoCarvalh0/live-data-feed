defmodule LiveDataFeed.Stock.StockServiceTest do
  use ExUnit.Case, async: true

  alias LiveDataFeed.Stock.StockService

  describe "get_stocks_latest_data/0" do
    test "returns the latest data from all available stocks" do
      assert Enum.sort([
               %{
                 symbol: "AAPL",
                 current_price: 150.25,
                 timestamp: 1_676_529_345_000,
                 volume: 1234.5678
               },
               %{
                 symbol: "GOOG",
                 current_price: 2800.75,
                 timestamp: 1_676_529_345_000,
                 volume: 2345.6789
               },
               %{
                 symbol: "TSLA",
                 current_price: 700.10,
                 timestamp: 1_676_529_345_000,
                 volume: 3456.7890
               },
               %{
                 symbol: "AMZN",
                 current_price: 3300.50,
                 timestamp: 1_676_529_345_000,
                 volume: 4567.8901
               }
             ]) ==
               Enum.sort(StockService.get_stocks_latest_data())
    end

    test "returns an empty list when there's no stock registered yet" do
      StockService.get_stocks_latest_data() == []
    end
  end

  describe "register_stocks/1" do
    test "returns :ok if stocks data were registered successfully" do
      stocks_to_register = [
        %{
          symbol: "GOOG",
          current_price: 2800.75,
          timestamp: 1_676_529_345_000,
          volume: 2345.6789
        },
        %{
          symbol: "TSLA",
          current_price: 700.10,
          timestamp: 1_676_529_345_000,
          volume: 3456.7890
        }
      ]

      assert :ok = StockService.register_stocks(stocks_to_register)
    end

    test "returns :ok if stocks list is empty" do
      stocks_to_register = []

      assert :ok = StockService.register_stocks(stocks_to_register)
    end

    test "returns error with reason if any of the stocks are invalid" do
      stocks_to_register = [
        %{
          symbol: 123,
          current_price: 700.10,
          timestamp: 1_676_529_345_000,
          volume: 3456.7890
        }
      ]

      assert {:error, reason} = StockService.register_stocks(stocks_to_register)
      assert reason == :invalid_stock
    end
  end
end
