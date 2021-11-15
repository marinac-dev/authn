defmodule Authn.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  # * Deriving WebAuthn structure to JSON, encode all fields
  require Protocol
  Protocol.derive(Jason.Encoder, Wax.Challenge)

  schema "users" do
    field :password, :string
    field :username, :string

    # * Fields used for WebAuthn
    field :key_id, :string
    field :cose_key, :binary

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password])
    |> validate_required([:username, :password])
    |> unique_constraint(:username)
  end

  def yubikey_changeset(user, attrs) do
    user
    |> cast(attrs, [:key_id, :cose_key])

    # |> unique_constraint(:username)
  end
end
