defmodule Authn.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Authn.Repo,
      # Start the Telemetry supervisor
      AuthnWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Authn.PubSub},
      # Start the Endpoint (http/https)
      AuthnWeb.Endpoint
      # Start a worker by calling: Authn.Worker.start_link(arg)
      # {Authn.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Authn.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AuthnWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
