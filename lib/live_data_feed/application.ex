defmodule LiveDataFeed.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        LiveDataFeedWeb.Telemetry,
        {DNSCluster, query: Application.get_env(:live_data_feed, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: LiveDataFeed.PubSub},
        # Start a worker by calling: LiveDataFeed.Worker.start_link(arg)
        # {LiveDataFeed.Worker, arg},
        # Start to serve requests, typically the last entry
        LiveDataFeedWeb.Endpoint
      ]
      |> maybe_add_price_streamer()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveDataFeed.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_add_price_streamer(children) do
    if Application.get_env(:live_data_feed, :start_price_streamer?, true) do
      children ++ [{LiveDataFeed.PriceStreamer, name: :price_streamer}]
    else
      children
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveDataFeedWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
