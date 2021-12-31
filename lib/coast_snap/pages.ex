defmodule CoastSnap.Pages do

    alias CoastSnap.Repo
    alias CoastSnap.Resources.Page

    import Ecto.Query

    def create_page(attrs \\ %{}) do
        %Page{}
        |> Page.changeset(attrs)
        |> Repo.insert
    end

    def update_page(page, attrs \\ %{}) do
        page
        |> Page.changeset(attrs)
        |> Repo.update()
    end

    def destroy(page) do
        {:ok, _} = Repo.delete(page)
    end

    def list_pages() do
        Page
        |> order_by(:position)
        |> Repo.all
    end

    def tree() do
        pages = list_pages()
        parents = Enum.filter pages, &(is_nil(&1.parent_id))
        Enum.map parents, fn parent ->
            children =
                Enum.filter( pages, fn c -> c.parent_id == parent.id end)
                |> Enum.sort( &(&1.position <= &2.position))
            [ parent, children ]
        end
    end

    def list_parents() do
        qry = from p in Page, where: is_nil(p.parent_id)
        Repo.all(qry)
    end

    def list_children(page) do
        qry = from p in Page, where: p.parent_id==^page.id
        Repo.all(qry)
    end

    def list_all_children() do
        qry = from p in Page, where: not(is_nil(p.parent_id))
        Repo.all(qry)
    end

    def get_page(id) do
        Repo.get(Page, id)
    end

    def get_page_by_slug(slug) do
        Repo.get_by(Page, slug: slug)
    end

end
