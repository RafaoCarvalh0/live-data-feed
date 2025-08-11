# LiveDataFeed - Technical Test for Arionkoder

This project is a technical test developed for the company Arionkoder. It simulates a stock price streaming service that periodically fetches stock data, stores it, and broadcasts updates to subscribed clients.

![Build & Tests](https://github.com/RafaoCarvalh0/live-data-feed/actions/workflows/elixir.yml/badge.svg)

## Features

- Periodic fetching of stock prices via a configurable price fetcher.
- Storage and updating of stock data with validation.
- Broadcasting detailed stock price updates with change calculations via Phoenix PubSub.
- Client simulator service to subscribe/unsubscribe from stock symbols.
- In-memory client registry for managing client processes.

## How to run and usage example

1. **Install dependencies:**

   ```bash
   mix deps.get
   ```

2. **Start the application:**

   ```bash
   iex -S mix
   ```

3. **Use the service alias for ease of use:**

   ```elixir
   alias LiveDataFeed.Simulators.ClientSimulatorService
   ```

4. **Start a client simulation with a custom name:**

   ```elixir
   ClientSimulatorService.start_client(:client1)
   ```

5. **Subscribe the client to a stock symbol:**

   ```js
   // use this function to check available symbols
   ClientSimulatorService.list_available_symbols
   ["AAPL", "GOOG", "TSLA", "AMZN"]

   ClientSimulatorService.subscribe_to_symbol(:client1, "AAPL")
   [info] [PID #PID<0.359.0> | Client :client1] Subscribed to "stocks:AAPL"
   :ok
   // the client will start receiving updates after a few moments
   [info] [PID #PID<0.359.0> | Client :client1] Received update from "AAPL": %{
     timestamp: 1754877797948,
     symbol: "AAPL",
     current_price: 14384,
     volume: 1126.793,
     last_price: 14482,
     price_change: -98,
     price_change_percent: -1
   }

   ```

>#### NOTE: Clients are able to subscribe to more than 1 symbol at once. 
>#### Just execute the `subscribe_to_symbol/2` function with another symbol of your choosing

6. **Unsubscribe from a stock symbol:**

   ```js
   ClientSimulatorService.unsubscribe_from_symbol(:client1, "AAPL")
   [info] [PID #PID<0.359.0> | Client :client1] Unsubscribed from "stocks:AAPL"
   :ok
   ```

7. **Remove a client:**

   ```elixir
   LiveDataFeed.Simulators.ClientSimulatorService.remove_client(:client1)
   ```

8. **List all clients:**

   ```js
    ClientSimulatorService.list_clients
    %{client: #PID<0.481.0>, client2: #PID<0.483.0>}
   ```

