defmodule VirtualRcAlt.NoteBlock do
  defstruct [:note]
  def new(note \\ "") do
    %__MODULE__{note: note}
  end
end
