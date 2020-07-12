defmodule VirtualRcAlt.LinkBlock do
  defstruct [:url]
  def new(url \\ "") do
    %__MODULE__{url: url}
  end
end
