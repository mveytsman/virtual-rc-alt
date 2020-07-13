defmodule VirtualRcAltWeb.EditCellComponent do
  use VirtualRcAltWeb, :live_component

  alias VirtualRcAlt.{NoteBlock, LinkBlock}

  def render(%{contents: %NoteBlock{note: note}} = assigns) do
    ~L"""
    <div class="modal-container">
      <div
        phx-capture-click="close-editor"
        phx-window-keydown="close-editor"
        phx-key="escape"
        class="modal-inner-container">
        <form phx-submit="save-editor">
        <fieldset>
          <label for="content">Note</label>
          <textarea placeholder="note..." name="content"><%= note %></textarea>
          <div class="float-right">
            <a href="#" phx-click="close-editor" class="button button-outline">Close</a>
            <input class="button" type="submit" value="Save">
          </div>
        </fieldset>
        </form>
      </div>
    </div>
    """
  end

  def render(%{contents: %LinkBlock{url: url}} = assigns) do
    ~L"""
    <div class="modal-container">
      <div
        phx-capture-click="close-editor"
        phx-window-keydown="close-editor"
        phx-key="escape"
        class="modal-inner-container">
        <form phx-submit="save-editor">
        <fieldset>
          <label for="content">URL</label>
          <input type="text" placeholder="https://..." name="content" value="<%= url %>"/>
          <div class="float-right">
            <a href="#" phx-click="close-editor" class="button button-outline">Close</a>
            <input class="button" type="submit" value="Save">
          </div>
        </fieldset>
        </form>
      </div>
    </div>
    """
  end


end
