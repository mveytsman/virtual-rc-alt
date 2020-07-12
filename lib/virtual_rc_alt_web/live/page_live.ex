defmodule VirtualRcAltWeb.PageLive do
  use VirtualRcAltWeb, :live_view

  alias VirtualRcAltWeb.GridCellComponent

  alias VirtualRcAlt.Grid

  @impl true
  def mount(_params, _session, socket) do
    width = 50
    height = 25
    origin = {0,0}
    player = Grid.register_player("Max")
    viewport = Grid.get_viewport(origin, width, height)

    Grid.subscribe()

    {:ok, assign(socket, origin: origin, width: width, height: height, viewport: viewport, player: player)}
  end

  @impl true
  def handle_event("move", %{"key" => key}, socket) do
    player = case key do
      "w" -> Grid.move(:up)
      "a" -> Grid.move(:left)
      "s" -> Grid.move(:down)
      "d" -> Grid.move(:right)

      "ArrowUp" -> Grid.move(:up)
      "ArrowLeft" -> Grid.move(:left)
      "ArrowDown" -> Grid.move(:down)
      "ArrowRight" -> Grid.move(:right)

      "x" -> Grid.create_or_destroy_block()

      _ -> socket.assigns.player
    end

    {:noreply, assign(socket, player: player)}
  end

  @impl true
  def handle_info({:update_cell, position, value}, state) do
    # TODO: check viewport
    send_update GridCellComponent, id: position, contents: value

    {:noreply, state}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div><%= inspect @  player %></div>
    <div id="grid" class="grid" phx-window-keydown="move">
    <%= for y <- y_range(@origin, @height), x <- x_range(@origin, @width) do %>
      <%= live_component @socket, GridCellComponent, id: {x,y}, x: x, y: y, contents: @viewport[{x,y}]%>
    <% end %>
    </div>
    """
  end

  defp x_range({x,_}, width), do: x..x+width-1
  defp y_range({_,y}, height), do: y..y+height-1

end
