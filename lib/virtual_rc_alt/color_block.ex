defmodule VirtualRcAlt.ColorBlock do
  defstruct [:color]

  def new do
    %__MODULE__{color: :gray}
  end
end
