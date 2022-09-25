defmodule StormstoutWeb.SessionController do
  @moduledoc false

  use StormstoutWeb, :controller

  alias Stormstout.{Accounts, Session}
  alias StormstoutWeb.UserAuth

  action_fallback StormstoutWeb.FallbackController

  def create(conn, params) do
    with {:ok, user} <- Accounts.verify_wallet_address(params) do
      # add fetcher
      Session.Leader.create_session(address: user.address)

      UserAuth.log_in_user(conn, user)
    end
  end

  def delete(conn, _params), do: UserAuth.log_out_user(conn)
end
