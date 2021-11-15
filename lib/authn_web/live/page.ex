defmodule AuthnWeb.Live.Page do
  use AuthnWeb, :live_view

  require Logger

  alias Authn.{Accounts, Accounts.User}

  def mount(_args, _session, socket) do
    changeset = Accounts.user_init()

    {:ok,
     socket
     |> assign(:login, nil)
     |> assign(:changeset, changeset)
     |> assign(:authenticator, false)
     |> assign(:with_webauthn, false)}
  end

  def handle_params(_params, _uri, %{assigns: assigns} = socket) do
    # ? Introspect when live action changes via push_patch | ONLY DEV
    # if Mix.env() == :dev, do: IO.inspect(assigns)
    {:noreply, socket}
  end

  def handle_event("maybe-login", %{"user" => %{"username" => username}}, socket) do
    case Accounts.get_user_by_username(username) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:info, "User not found. Please register!")
         |> push_patch(to: "/register")}

      user ->
        {:noreply,
         socket
         |> assign(:user, user)
         |> push_patch(to: "/authenticate")}
    end
  end

  def handle_event("register", %{"user" => params}, socket) do
    case Accounts.create_user(params) do
      {:ok, user} ->
        challenge = Wax.new_registration_challenge([])

        payload = %{
          challenge_b64: challenge.bytes |> Base.encode64(),
          relying_id: challenge.rp_id,
          user: user.username
        }

        {:noreply,
         socket
         |> assign(:user, user)
         |> assign(:challenge, challenge)
         |> push_event("attestation", payload)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:changeset, changeset)}
    end
  end

  def handle_event("authenticate", %{"user" => %{"username" => username}}, socket) do
    case Accounts.get_user_by_username(username) do
      %User{} = user ->
        cred_id = user.key_id
        cose_key = user.cose_key |> format_key(:btt)
        challenge = Wax.new_authentication_challenge([{cred_id, cose_key}], [])
        challenge_b64 = challenge.bytes |> Base.encode64()
        data = %{challenge: challenge_b64, credential_ids: [cred_id]}

        {:noreply,
         socket
         |> assign(:challenge, challenge)
         |> push_event("authentication", data)}

      nil ->
        {:noreply,
         socket
         |> put_flash(:info, "User not found, please register!")
         |> push_patch(to: "/register")}
    end
  end

  # ? Events for Authn Hooks
  def handle_event("attestation", %{"yubikey" => params}, %{assigns: assigns} = socket) do
    %{
      "attestationObject" => attestation_object_b64,
      "clientDataJSON" => client_data_json,
      "rawID" => raw_id_b64,
      "type" => "public-key"
    } = params

    attestation_object = attestation_object_b64 |> Base.decode64!()

    with {:ok, {key, _result}} <- Wax.register(attestation_object, client_data_json, assigns.challenge),
         {:ok, _user} <-
           Accounts.update_user_yubikey(assigns.user, %{key_id: raw_id_b64, cose_key: format_key(key, :ttb)}) do
      {:noreply,
       socket
       |> put_flash(:info, "Key added successfully!")
       |> push_patch(to: "/authenticate")}
    else
      {:error, error} ->
        Logger.debug("Wax: attestation object validation failed with error #{inspect(error)}")

        {:noreply,
         socket
         |> put_flash(:error, "Key registration failed")}
    end
  end

  def handle_event("authentication", %{"webauthn" => params}, %{assigns: assigns} = socket) do
    %{
      "authenticatorData" => authenticator_data_b64,
      "clientDataJSON" => client_data_json,
      "rawID" => raw_id_b64,
      "sig" => sig_b64,
      "type" => "public-key"
    } = params

    sig = sig_b64 |> Base.decode64!()
    auth_data = authenticator_data_b64 |> Base.decode64!()

    case Wax.authenticate(raw_id_b64, auth_data, sig, client_data_json, assigns.challenge) do
      {:ok, _} ->
        # * Login or start a session
        {:noreply,
         socket
         |> put_flash(:info, "Success!")}

      {:error, reason} ->
        Logger.warn("Error: #{inspect(reason)}")

        {:noreply,
         socket
         |> put_flash(:error, "Authn failed")}
    end
  end

  # * Private helpers

  # ? We transform cose key to binary because it's not indexed or searched for
  defp format_key(key, :btt), do: key |> :erlang.binary_to_term()
  defp format_key(key, :ttb), do: key.attested_credential_data.credential_public_key |> :erlang.term_to_binary()
end
