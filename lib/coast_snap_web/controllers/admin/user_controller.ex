defmodule CoastSnapWeb.Admin.UserController do

    use CoastSnapWeb, :controller
    alias CoastSnap.Accounts

    def index(conn, params) do
        page = Map.get(params, "page", 1)
        users = Accounts.list_users(:paged, page)
        render(conn, :index, %{ users: users, page: page })
    end

    def confirm(conn, %{ "id" => id }) do
        user = Accounts.get_user!(id)
        Accounts.confirm_user(user)
        redirect conn, to: "/admin/users"
    end

    def forgot_password(conn, %{ "id" => id }) do
        user = Accounts.get_user!(id)
        email_text = Accounts.deliver_user_reset_password_instructions(
            user,
            &Routes.user_reset_password_url(conn, :edit, &1)
        )
        render(conn, :forgot_password, %{ user: user, contents: email_text })
    end

    def delete(conn, %{ "id" => id }) do
        user = Accounts.get_user!(id)
        Accounts.destroy_user(user)
        redirect conn, to: "/admin/users"
    end

end
