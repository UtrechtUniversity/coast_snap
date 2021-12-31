defmodule CoastSnapWeb.VisitorView do
    use CoastSnapWeb, :view

    def show(page, country) do
        case country do
            "nl" -> page.content_nl
            "en" -> page.content_en
            "ge" -> page.content_ge
        end
    end

end
