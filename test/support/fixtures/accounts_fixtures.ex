defmodule Authn.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Authn.Accounts` context.
  """

  @doc """
  Generate a unique user username.
  """
  def unique_user_username, do: "some username#{System.unique_integer([:positive])}"

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        cose_key: "some cose_key",
        key_id: "some key_id",
        password: "some password",
        username: unique_user_username()
      })
      |> Authn.Accounts.create_user()

    user
  end
end
