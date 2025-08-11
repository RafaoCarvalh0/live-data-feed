defmodule LiveDataFeed.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnit.Case, async: false

      setup do
        :mnesia.sync_transaction(fn ->
          :mnesia.clear_table(:stock_prices)
        end)

        on_exit(fn ->
          :mnesia.sync_transaction(fn ->
            :mnesia.clear_table(:stock_prices)
          end)
        end)

        :ok
      end
    end
  end

  setup_all do
    :mnesia.stop()
    :mnesia.delete_schema([node()])

    :mnesia.create_schema([node()])
    :mnesia.start()

    {:atomic, :ok} =
      :mnesia.create_table(:stock_prices, [
        {:attributes, [:symbol, :price_in_cents]},
        {:ram_copies, [node()]},
        {:type, :set}
      ])

    :mnesia.wait_for_tables([:stock_prices], 5_000)

    :ok
  end
end
