defmodule VirtualRcAltWeb.GridCellComponent do
 use VirtualRcAltWeb, :live_component

 alias VirtualRcAlt.{Player, ColorBlock}

  def render(assigns) do
    ~L"""
    <div id="<%= "#{@x},#{@y}" %>" class="<%= class(@contents) %>"><%= inner_content(@contents) %></div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  defp inner_content(%Player{initial: initial}), do: initial
  defp inner_content(_), do: ""

  defp class(%ColorBlock{color: color}), do: "grid-cell block #{color}"
  defp class(%Player{facing: facing}), do: "grid-cell facing #{facing}"
  defp class(_), do: "grid-cell"
end
