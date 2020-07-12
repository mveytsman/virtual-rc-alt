defmodule VirtualRcAlt.ColorBlock do
  defstruct [:color]

  def new, do: new(:gray)
  def new(color) do
    %__MODULE__{color: color}
  end

  def change_color(%__MODULE__{color: color} = color_block) do
    color = case color do
      :gray -> :pink
      :pink -> :orange
      :orange -> :green
      :green -> :blue
      :blue -> :purple
      :purple -> :yellow
      :yellow -> :gray

      _ -> :gray
    end

    %{color_block | color: color}
  end
end
