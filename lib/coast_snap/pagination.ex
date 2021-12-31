# see also HTML helper in helpers

defmodule CoastSnap.Pagination do
    import Ecto.Query
    alias CoastSnap.Repo

    def query(query, page, per_page: per_page) when is_binary(page) do
        query(query, String.to_integer(page), per_page: per_page)
    end

    def query(query, page, per_page: per_page) do
        query
        |> limit(^(per_page + 1))
        |> offset(^(per_page * (page - 1)))
        |> Repo.all()
    end


    def page(query, page, per_page: per_page) when is_binary(page) do
        page(query, String.to_integer(page), per_page: per_page)
    end

    def page(query, page, per_page: per_page) do
        results = query(query, page, per_page: per_page)
        has_next = length(results) > page
        has_prev = page > 1
        count = Repo.one(from(t in subquery(query), select: count("*")))

        %{
            has_next: has_next,
            has_prev: has_prev,
            prev_page: page - 1,
            page: page,
            next_page: page + 1,
            first: (page - 1) * per_page + 1,
            last: min(page * per_page, count),
            count: count,
            page_count: ceil(count / per_page),
            list: Enum.slice(results, 0, per_page) # compensates for asking one more per page
        }
    end

end
