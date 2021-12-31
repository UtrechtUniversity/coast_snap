# https://dev.to/ricardoruwer/create-a-paginator-using-elixir-and-phoenix-1hnk

defmodule CoastSnapWeb.Helpers.PaginationHelper do
    use Phoenix.HTML

    @max_visible_pages 3

    def render(conn, data, class: class) do
        first = first_button(conn, data)
        prev = prev_button(conn, data)
        pages = page_buttons(conn, data)
        next = next_button(conn, data)
        last = last_button(conn, data)

        content_tag(:ul, [first, prev, pages, next, last], class: class)
    end

    defp first_button(conn, data) do
        first_page = 1
        disabled = data.page == first_page
        params = build_params(conn, first_page)

        content_tag(:li, disabled: disabled) do
            link to: "?#{params}", rel: "prev" do
                "<<"
            end
        end
    end

    defp prev_button(conn, data) do
        page = data.page - 1
        disabled = data.page == 1
        params = build_params(conn, page)

        content_tag(:li, disabled: disabled) do
            link to: "?#{params}", rel: "prev" do
                "<"
            end
        end
    end

    defp page_buttons(conn, data) do
        left = max(1, data.page - @max_visible_pages)
        # in case the database is empty
        page_count = case data.page_count == 0 do
          true -> 1
          false -> data.page_count
        end
        right = min(page_count, data.page + @max_visible_pages)

        for page <- left..right do
            class = if data.page == page, do: "active"
            disabled = data.page == page
            params = build_params(conn, page)

            content_tag(:li, class: class, disabled: disabled) do
                link(page, to: "?#{params}")
            end
        end
    end

    defp next_button(conn, data) do
        page = data.page + 1
        disabled = data.page >= data.page_count
        params = build_params(conn, page)

        content_tag(:li, disabled: disabled) do
            link to: "?#{params}", rel: "next" do
                ">"
            end
        end
    end

    defp last_button(conn, data) do
        last_page = data.page_count
        disabled = (data.page == last_page) or last_page < 2
        params = build_params(conn, last_page)

        content_tag(:li, disabled: disabled) do
            link to: "?#{params}", rel: "prev" do
                ">>"
            end
        end
    end

    defp build_params(conn, page) do
        conn.query_params |> Map.merge(%{ "page" => page }) |> URI.encode_query()
    end
end
