defmodule Authn.Repo do
  use Ecto.Repo,
    otp_app: :authn,
    adapter: Ecto.Adapters.Postgres
end
