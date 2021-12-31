# https://danielwachtel.com/phoenix/adding-global-view-helpers-phoenix-app

defmodule CoastSnapWeb.Helpers.Helper do
    def truncate(str, size) do
        case String.length(str) > size do
            true -> "#{String.slice(str, 0, size)}..."
            false -> str
        end
    end
end
