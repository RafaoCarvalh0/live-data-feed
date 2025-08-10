defmodule LiveDataFeed.Stock.StockRepositoryTest do
  use ExUnit.Case, async: true

  alias LiveDataFeed.Stock.StockRespository

  setup do
    :mnesia.clear_table(:stock_prices)
    :ok
  end

  describe "upsert_stock/2" do
    test "returns ok when insert is successful" do
      assert :ok = StockRespository.upsert_stock("AAPL", 15000)

      {:ok, inserted_data} = get_data_from_mnesia_table(:stock_prices, "AAPL")

      assert inserted_data == [{:stock_prices, "AAPL", 15000}]
    end

    test "returns updated data when the primary key already exists" do
      :ok = StockRespository.upsert_stock("AAPL", 0)

      assert :ok = StockRespository.upsert_stock("AAPL", 15500)

      {:ok, updated_data} = get_data_from_mnesia_table(:stock_prices, "AAPL")

      assert updated_data == [{:stock_prices, "AAPL", 15500}]
    end

    test "does not duplicate record when a existent primary key is sent" do
      :ok = StockRespository.upsert_stock("AAPL", 15)
      :ok = StockRespository.upsert_stock("AAPL", 15500)

      records =
        :stock_prices
        |> get_data_from_mnesia_table("AAPL")
        |> case do
          {:ok, records} -> List.flatten(records)
          _ -> []
        end

      assert length(records) == 1
      assert records == [{:stock_prices, "AAPL", 15500}]
    end
  end

  describe "get_stocks_by_symbols/1" do
    test "returns a list of found stock price records when they exist" do
      :ok = insert_data_into_mnesia_table({:stock_prices, "AAPL", 15000})
      :ok = insert_data_into_mnesia_table({:stock_prices, "GOOG", 280_000})

      {:ok, result} = StockRespository.get_stocks_by_symbols(["AAPL", "GOOG"])

      records = List.flatten(result)

      assert {:stock_prices, "AAPL", 15000} in records
      assert {:stock_prices, "GOOG", 280_000} in records
    end

    test "return an empty list when any of the stocks exist" do
      {:ok, result} = StockRespository.get_stocks_by_symbols(["NON_EXISTENT"])

      records = List.flatten(result)

      assert records == []
    end
  end

  defp get_data_from_mnesia_table(table, primary_key) do
    data_to_read = fn ->
      :mnesia.read({table, primary_key})
    end

    data_to_read
    |> :mnesia.transaction()
    |> case do
      {:atomic, data} -> {:ok, data}
      {:aborted, reason} -> {:error, reason}
    end
  end

  defp insert_data_into_mnesia_table(data) do
    transaction = fn ->
      :mnesia.write(data)
    end

    transaction
    |> :mnesia.transaction()
    |> case do
      {:atomic, upserted_stock} -> {:ok, upserted_stock}
      {:aborted, reason} -> {:error, reason}
    end

    Process.sleep(10)
  end
end
