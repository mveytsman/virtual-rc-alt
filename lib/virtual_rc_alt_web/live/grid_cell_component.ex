defmodule VirtualRcAltWeb.GridCellComponent do
  use VirtualRcAltWeb, :live_component

  alias VirtualRcAlt.{Player, ColorBlock, NoteBlock, LinkBlock}

  def mount(socket) do
    {:ok, assign(socket, edit: false)}
  end

  def update(%{edit: true}, %{assigns: %{id: position, contents: contents}} = socket) do
    # Only edit notes and links

    case contents do
      %NoteBlock{} -> send(self(), {:open_editor, position, contents})
      %LinkBlock{} ->  send(self(), {:open_editor, position, contents})
      _ ->  nil
    end

    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end


  def render(%{contents: %ColorBlock{color: color}} = assigns) do
    ~L"""
    <div id="<%= "#{@x},#{@y}" %>" class="grid-cell block <%= color %>"></div>
    """
  end

  def render(%{contents: %NoteBlock{note: note}} = assigns) do
    ~L"""
    <div id="<%= "#{@x},#{@y}" %>" class="grid-cell block yellow <%= if @currently_facing, do: "show-tooltip", else: ""%>" data-tooltip="<%= note_tooltip(note) %>"><i class="fa fa-sticky-note-o"></i></div>
    """
  end

  def render(%{contents: %LinkBlock{url: url}} = assigns) do
    ~L"""
    <div id="<%= "#{@x},#{@y}" %>" class="grid-cell block green <%= if @currently_facing, do: "show-tooltip", else: ""%>" data-tooltip="<%= link_tooltip(url) %>"><a href="<%= url %>" target="_blank"><i style="text-color: white;" class="fa fa-link"></i></a></div>
    """
  end

  def render(%{contents: %Player{facing: facing, initial: initial}} = assigns) do
    ~L"""
    <div id="<%= "#{@x},#{@y}" %>" class="grid-cell facing <%= facing %>"><%= initial %></div>
    """
  end

  def render(assigns) do
    ~L"""
    <div id="<%= "#{@x},#{@y}" %>" class="grid-cell"></div>
    """
  end

  def edit(id) do
    send_update(__MODULE__, id: id, edit: true)
  end

  defp note_tooltip(note) do
    if note == nil || note == "" do
      "press `e` to write a note"
    else
      note
    end
  end

  defp link_tooltip(url) do
    if url == nil || url == "" do
      "press `e` to add a link"
    else
      url
    end
  end
end
