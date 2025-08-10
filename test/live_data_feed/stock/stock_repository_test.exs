defmodule LiveDataFeed.Stock.StockRepositoryTest do
  use ExUnit.Case, async: true

  alias LiveDataFeed.Stock.StockRespository
  alias LiveDataFeed.Fixtures.StockFixtures

  setup do
    StockFixtures.clear_stock_prices_table()
  end

  describe "upsert_stocks/2" do
    test "returns ok when insert is successful" do
      input = [
        %{
          symbol: "AAPL",
          price: 15000
        }
      ]

      assert :ok = StockRespository.upsert_stocks(input)

      {:ok, inserted_data} = StockFixtures.get_stock_by_symbol("AAPL")

      assert inserted_data == [{:stock_prices, "AAPL", 15000}]
    end

    test "returns updated data when the primary key already exists" do
      :ok =
        StockRespository.upsert_stocks([
          %{
            symbol: "AAPL",
            price: 0
          }
        ])

      assert :ok =
               StockRespository.upsert_stocks([
                 %{
                   symbol: "AAPL",
                   price: 15500
                 }
               ])

      {:ok, updated_data} = StockFixtures.get_stock_by_symbol("AAPL")

      assert updated_data == [{:stock_prices, "AAPL", 15500}]
    end

    test "does not duplicate record when a existent primary key is sent" do
      assert :ok =
               StockRespository.upsert_stocks([
                 %{
                   symbol: "AAPL",
                   price: 15
                 },
                 %{
                   symbol: "AAPL",
                   price: 15500
                 }
               ])

      records =
        "AAPL"
        |> StockFixtures.get_stock_by_symbol()
        |> case do
          {:ok, records} -> List.flatten(records)
          _ -> []
        end

      assert length(records) == 1
      assert records == [{:stock_prices, "AAPL", 15500}]
    end

    test "returns error with reason when an invalid input is provided" do
      assert {:error, _reason} = StockRespository.upsert_stocks(nil)
    end
  end

  describe "get_stocks_by_symbols/1" do
    test "returns a list of found stock price records when they exist" do
      :ok = StockFixtures.create_stock("AAPL", 15000)
      :ok = StockFixtures.create_stock("GOOG", 280_000)

      {:ok, result} = StockRespository.get_stocks_by_symbols(["AAPL", "GOOG"])

      assert Enum.sort(result) ==
               Enum.sort([%{symbol: "AAPL", price: 15000}, %{symbol: "GOOG", price: 280_000}])
    end

    test "return an empty list when any of the stocks exist" do
      {:ok, result} = StockRespository.get_stocks_by_symbols(["NON_EXISTENT"])

      records = List.flatten(result)

      assert records == []
    end

    test "returns error with reason when an invalid input is provided" do
      assert {:error, _reason} = StockRespository.get_stocks_by_symbols(nil)
    end
  end
end
