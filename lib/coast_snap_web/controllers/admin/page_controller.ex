defmodule CoastSnapWeb.Admin.PageController do

    use CoastSnapWeb, :controller

    alias CoastSnap.Resources.Page
    alias CoastSnap.Pages

    def index(conn, _params) do
        pages =
            Pages.tree()
            |> List.flatten()

        parents_with_children =
            Pages.list_all_children()
            |> Enum.map(&(&1.parent_id))
            |> MapSet.new()

        render(conn, :index, %{ pages: pages, parents_with_children: parents_with_children })
    end

    def new(conn, params) do
        parent_id = Map.get(params, "parent_id", nil)
        parents = Pages.list_parents()
        changeset = Page.changeset(%Page{ parent_id: parent_id })
        render(conn, :new, %{ changeset: changeset, parents: parents })
    end

    def create(conn, %{"page" => page_params}) do
        case Pages.create_page(page_params) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "Page has been created")
            |> redirect(to: "/admin/pages")

          {:error, %Ecto.Changeset{} = changeset} ->
            parents = Pages.list_parents()
            render(conn, "new.html", %{ changeset: changeset, parents: parents })
        end
    end

    def edit(conn, %{ "id" => id }) do
        page = Pages.get_page(id)
        parents = Pages.list_parents()
        changeset = Page.changeset(page)
        render(conn, :edit, %{ changeset: changeset, page: page, parents: parents })
    end

    def update(conn, %{ "id" => id, "page" => page_params }) do
        page = Pages.get_page(id)
        result = Pages.update_page(page, page_params)
        case result do
          {:ok, _} ->
            conn
            |> put_flash(:info, "Page updated successfully.")
            |> redirect(to: "/admin/pages")
          {:error, %Ecto.Changeset{} = changeset} ->
            parents = Pages.list_parents()
            render(conn, "edit.html", %{ page: page, changeset: changeset, parents: parents })
        end
    end

    def show(conn, %{ "id" => id }) do
        page = Pages.get_page(id)
        render(conn, :show, page: page)
    end

    def delete(conn, %{ "id" => id }) do
        page = Pages.get_page(id)
        {:ok, _article} = Pages.destroy(page)

        conn
        |> put_flash(:info, "Page(s) deleted successfully.")
        |> redirect(to: "/admin/pages")
    end

end
