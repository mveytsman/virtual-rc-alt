defmodule VirtualRcAltWeb.PageLive do
  use VirtualRcAltWeb, :live_view

  alias VirtualRcAltWeb.GridCellComponent

  alias VirtualRcAlt.{Grid, Player}

  @impl true
  def mount(_params, _session, socket) do
    width = 30
    height = 20
    origin = {0, 0}
    player = Grid.register_player("Max")
    viewport = Grid.get_viewport(origin, width, height)

    Grid.subscribe()

    {:ok,
     assign(socket,
       origin: origin,
       width: width,
       height: height,
       viewport: viewport,
       player: player
     )}
  end

  @impl true
  def handle_event(
        "keydown",
        %{"key" => key},
        socket
      ) do
    socket =
      case key do
        "w" -> move(socket, :up)
        "a" -> move(socket, :left)
        "s" -> move(socket, :down)
        "d" -> move(socket, :right)
        "ArrowUp" -> move(socket, :up)
        "ArrowLeft" -> move(socket, :left)
        "ArrowDown" -> move(socket, :down)
        "ArrowRight" -> move(socket, :right)
        "x" -> create_or_destroy_block(socket)
        "c" -> change_block_color(socket)
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:update_cell, {x, y} = position, value},
        %{assigns: %{width: width, height: height, origin: {x_origin, y_origin}}} = socket
      ) do
    if x > x_origin && x < x_origin + width && y > y_origin && y < y_origin + height do
      require Logger; Logger.info("Cell update: #{x}, #{y}: #{inspect value}")
      send_update(GridCellComponent, id: position, contents: value)
    end

    {:noreply, socket}
  end

  @impl true
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~L"""
    <div id="grid:<%= inspect @origin %>" class="grid" phx-window-keydown="keydown">
    <%= for y <- y_range(@origin, @height), x <- x_range(@origin, @width) do %>
      <%= live_component @socket, GridCellComponent, id: {x,y}, x: x, y: y, contents: @viewport[{x,y}], currently_facing: false %>
    <% end %>
    </div>
    """
  end

  defp x_range({x, _}, width), do: x..(x + width - 1)
  defp y_range({_, y}, height), do: y..(y + height - 1)

  defp move(
         %{
           assigns: %{
             player: player,
             origin: {x_origin, y_origin} = origin,
             viewport: viewport,
             width: width,
             height: height
           }
         } = socket,
         direction
       ) do
    new_player = Grid.move(direction)

    # Update the square we're facing
    send_update(GridCellComponent, id: facing(player), currently_facing: false)
    send_update(GridCellComponent, id: facing(new_player), currently_facing: true)


    # Update viewport if needed
    {x, y} = new_player.position
    new_origin =
      cond do
        x - x_origin <= 2 && x_origin > 0 ->
          {x_origin - 1, y_origin}

        x - x_origin >= width - 2 ->
          {x_origin + 1, y_origin}

        y - y_origin <= 2 && y_origin > 0 ->
          {x_origin, y_origin - 1}

        y - y_origin >= height - 2 ->
          {x_origin, y_origin + 1}

        true ->
          origin
      end

    new_viewport =
      if new_origin != origin do
        Grid.get_viewport(origin, width, height)
      else
        viewport
      end

    socket
    |> assign(player: new_player)
    |> assign(origin: new_origin)
    |> assign(viewport: new_viewport)
  end

  defp create_or_destroy_block(socket) do
    Grid.create_or_destroy_block()

    socket
  end

  defp change_block_color(socket) do
    Grid.change_block_color()

    socket
  end

  defp facing(%Player{position: {x,y}, facing: direction}) do
    case direction do
      :up -> {x, y - 1}
      :down -> {x, y + 1}
      :left -> {x - 1, y}
      :right -> {x + 1, y}
    end
  end
end
