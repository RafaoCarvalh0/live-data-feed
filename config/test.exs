import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :live_data_feed, LiveDataFeedWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "B6ZiiNGVlfrRLcNJstZe8puyGe8YUx42BmF4MQTYV0lzbB6qZBabarhkZ0J9jybQ",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :live_data_feed, start_price_streamer?: false
