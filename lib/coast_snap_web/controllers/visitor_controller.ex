defmodule CoastSnapWeb.VisitorController do

    use CoastSnapWeb, :controller

    alias CoastSnap.Pages

    def index(conn, params) do
        country = Map.get(params, "country", False)
        tree = Pages.tree()

        cond do
            country == False -> redirect(conn, to: "/nl")
            Enum.empty?(tree) == true -> render(conn, :index, tree: tree)
            Enum.empty?(tree) == false ->
                [[page|_]|_] = tree
                redirect(conn, to: "/#{country}/#{page.slug}")
        end
    end

    def show(conn, params) do
        slug = Map.get(params, "slug")
        page = Pages.get_page_by_slug(slug)
        country = Map.get(params, "country", "nl")
        tree = Pages.tree()
        render conn, :show, tree: tree, country: country, page: page
    end

end
