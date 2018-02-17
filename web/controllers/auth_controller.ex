defmodule Discuss.AuthController do
  use Discuss.Web, :controller
  plug(Ueberauth)

  alias Discuss.User

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, params) do
    user_params = %{
      email: auth.info.email,
      token: auth.credentials.token,
      provider: Atom.to_string(auth.provider)
    }

    changeset = User.changeset(%User{}, user_params)

    signin(conn, changeset)
  end

  def signout(conn, _params) do
    # put_session(:user_id, nil) will work, but it maby does not delete all collected user data so the whole session will be deleted here
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "Successfully signed out")
    |> redirect(to: topic_path(conn, :index))
  end

  defp signin(conn, changeset) do
    case insert_or_update(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back")
        |> put_session(:user_id, user.id)
        |> redirect(to: topic_path(conn, :index))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Error singing in")
        |> redirect(to: topic_path(conn, :index))
    end
  end

  defp insert_or_update(changeset) do
    case Repo.get_by(User, email: changeset.changes.email) do
      nil ->
        Repo.insert(changeset)

      user ->
        {:ok, user}
    end
  end
end
