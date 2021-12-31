defmodule CoastSnapWeb.Admin.PageView do
    use CoastSnapWeb, :view

    def options_for_parent(pages, current_page) do
        Enum.map(pages, &([key: &1.nav_nl, value: &1.id]))
        |> Enum.reject(&(&1[:value] == current_page.id))
    end

end
