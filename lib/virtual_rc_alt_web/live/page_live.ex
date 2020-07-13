defmodule VirtualRcAltWeb.PageLive do
  use VirtualRcAltWeb, :live_view

  alias VirtualRcAltWeb.{GridCellComponent, EditCellComponent}

  alias VirtualRcAlt.{Grid, Player, NoteBlock, LinkBlock}

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
       player: player,
       edit_cell: nil
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
        "e" -> edit_block(socket)
        _ -> socket
      end

    {:noreply, socket}
  end


  def handle_event("close-editor", _, socket) do
    {:noreply, assign(socket, edit_cell: nil)}
  end

  def handle_event("save-editor", %{"content" => content}, %{assigns: %{edit_cell: %{position: position}}} = socket) do
    Grid.edit_block(position, content)

    {:noreply, assign(socket, edit_cell: nil)}
  end
  @impl true
  @spec handle_info({:open_editor, any, any} | {:update_cell, {any, any}, any}, map) ::
          {:noreply, any}
  def handle_info(
        {:update_cell, {x, y} = position, value},
        %{assigns: %{width: width, height: height, origin: {x_origin, y_origin}}} = socket
      ) do
    if x >= x_origin && x < x_origin + width && y >= y_origin && y < y_origin + height do
      require Logger; Logger.info("Cell update: #{x}, #{y}: #{inspect value}")
      send_update(GridCellComponent, id: position, contents: value)
    end

    {:noreply, socket}
  end

  def handle_info({:open_editor, position, contents}, socket) do
    {:noreply, assign(socket, edit_cell: %{position: position, contents: contents})}
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
        Grid.get_viewport(new_origin, width, height)
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

  defp edit_block(%{assigns: %{player: player}} = socket) do
    GridCellComponent.edit(facing(player))

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
