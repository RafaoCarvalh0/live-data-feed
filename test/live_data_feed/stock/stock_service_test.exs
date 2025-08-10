defmodule LiveDataFeed.Stock.StockServiceTest do
  use ExUnit.Case, async: true
  use Mimic

  import ExUnit.CaptureLog

  alias LiveDataFeed.Fixtures.StockFixtures
  alias LiveDataFeed.Stock.StockRespository
  alias LiveDataFeed.Stock.StockService

  require Logger

  setup do
    original_level = Logger.level()
    Logger.configure(level: :info)

    on_exit(fn ->
      Logger.configure(level: original_level)
    end)

    StockFixtures.clear_stock_prices_table()
  end

  describe "get_stocks_data/0" do
    test "returns the data from available stocks" do
      Enum.each(["AAPL", "GOOG", "AMZN"], &StockFixtures.create_stock(&1, 0))

      assert Enum.sort([
               %{
                 symbol: "AAPL",
                 price: 0
               },
               %{
                 symbol: "GOOG",
                 price: 0
               },
               %{
                 symbol: "AMZN",
                 price: 0
               }
             ]) ==
               Enum.sort(StockService.get_stocks_data())
    end

    test "returns an empty list when there's no stock registered yet" do
      assert StockService.get_stocks_data() == []
    end

    test "returns and logs error when fetching data fails" do
      stub(StockRespository, :get_stocks_by_symbols, fn _ ->
        {:error, "any error"}
      end)

      logs =
        capture_log(fn ->
          assert {:error, :failed_to_fetch_stocks} = StockService.get_stocks_data()
        end)

      assert logs =~ ~S(Error while fetching stocks data. reason:)
    end
  end

  describe "set_stocks_data/1" do
    test "returns :ok if stocks data were registered successfully" do
      stocks_to_register = [
        %{
          symbol: "GOOG",
          price: 2800
        },
        %{
          symbol: "TSLA",
          price: 70010
        }
      ]

      assert :ok = StockService.set_stocks_data(stocks_to_register)
    end

    test "returns :ok if stocks list is empty" do
      stocks_to_register = []

      assert :ok = StockService.set_stocks_data(stocks_to_register)
    end

    test "returns error with reason if any of the stocks are invalid" do
      stocks_to_register = [
        %{
          symbol: 123,
          price: "foo"
        }
      ]

      logs =
        capture_log(fn ->
          assert {:error, reason} = StockService.set_stocks_data(stocks_to_register)
          assert reason == :invalid_stock_input
        end)

      assert logs =~
               ~S(Error while registering stocks. reason: :invalid, [%{symbol: 123, price: "foo"}])
    end
  end
end
