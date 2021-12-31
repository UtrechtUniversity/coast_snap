defmodule CoastSnapWeb.LayoutView do
  use CoastSnapWeb, :view

  def generate_nav(conn, tree) do
    country = Map.get(conn.params, "country", "nl")
    current_slug = Map.get(conn.params, "slug", false)

    ~E"""
    <ul id="main-nav" class="vertical medium-horizontal menu" data-responsive-menu="accordion medium-dropdown" data-animate="slide-in-down slide-out-up">
    <%= for [parent, children] <- tree do %>
        <%= if Enum.empty?(children) do %>
            <li class="<%= nav_class(parent.slug, current_slug) %>"><%= menu_link(parent, country) %></li>
        <% else %>
            <li class="has-submenu <%= nav_class(parent.slug, current_slug) %>">
                <%= menu_link(parent, country) %>
                <ul class="submenu menu vertical" data-submenu>
                    <%= for child <- children do %>
                        <li class="<%= nav_class(child.slug, current_slug) %>"><%= menu_link(child, country) %></li>
                    <% end %>
                </ul>
            </li>
        <% end %>
    <% end %>
    </ul>
    """
  end

  def menu_link(page, country) do
    nav = case country do
        "nl" -> page.nav_nl
        "en" -> page.nav_en
        "ge" -> page.nav_ge
        _ -> page.nav_nl
    end
    ~E"""
    <a href='<%= "/#{country}/#{page.slug}" %>'><%= nav %></a>
    """
  end

  def nav_class(slug, current_slug) do
    case slug == current_slug do
        true -> "active"
        false -> ""
    end
  end

  def change_language(conn, language \\ "nl") do
    slug = Map.get(conn.params, "slug", nil)
    case language do
        "nl" -> "/nl/#{slug}"
        "en" -> "/en/#{slug}"
        "ge" -> "/ge/#{slug}"
        _ -> "/nl/#{slug}"
    end
  end
end
