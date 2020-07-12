defmodule VirtualRcAltWeb.GridCellComponent do
  use VirtualRcAltWeb, :live_component

  alias VirtualRcAlt.{Player, ColorBlock, NoteBlock, LinkBlock}

  def render(%{contents: %ColorBlock{color: color}} = assigns) do
    ~L"""
    <div id="<%= "#{@x},#{@y}" %>" class="grid-cell block <%= color %>"></div>
    """
  end

  def render(%{contents: %NoteBlock{note: note}} = assigns) do
    ~L"""
    <div id="<%= "#{@x},#{@y}" %>" class="grid-cell block yellow <%= if @currently_facing, do: "show-tooltip", else: ""%>" data-tooltip="<%= note%>"><i class="fa fa-sticky-note-o"></i></div>
    """
  end

  def render(%{contents: %LinkBlock{url: url}} = assigns) do
    ~L"""
    <div id="<%= "#{@x},#{@y}" %>" class="grid-cell block green <%= if @currently_facing, do: "show-tooltip", else: ""%>" data-tooltip="<%= url%>"><a href="<%= url %>" target="_blank"><i style="text-color: white;" class="fa fa-link"></i></a></div>
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
end
