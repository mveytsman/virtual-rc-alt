defmodule VirtualRcAlt.Grid do
  use GenServer
  require Logger

  alias VirtualRcAlt.{Player, ColorBlock, NoteBlock, LinkBlock, PlayerMonitor}

  @width 500
  @height 500

  @topic "grid"

  # Client
  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def register_player(name), do: register_player(__MODULE__, name)
  def register_player(pid, name), do: GenServer.call(pid, {:register_player, name})

  def unregister_player(player_pid), do: unregister_player(__MODULE__, player_pid)

  def unregister_player(pid, player_pid),
    do: GenServer.call(pid, {:unregister_player, player_pid})

  def get_viewport(origin, width, height), do: get_viewport(__MODULE__, origin, width, height)

  def get_viewport(pid, origin, width, height),
    do: GenServer.call(pid, {:get_viewport, origin, width, height})

  def move(direction), do: move(__MODULE__, direction)
  def move(pid, direction), do: GenServer.call(pid, {:move, direction})

  def create_or_destroy_block(), do: create_or_destroy_block(__MODULE__)
  def create_or_destroy_block(pid), do: GenServer.call(pid, :create_or_destroy_block)

  def change_block_color(), do: change_block_color(__MODULE__)
  def change_block_color(pid), do: GenServer.call(pid, :change_block_color)

  def subscribe do
    Phoenix.PubSub.subscribe(VirtualRcAlt.PubSub, @topic)
  end

  # Server

  @impl true
  def init(_) do
    left_border = for y <- 0..(@height - 1), do: {0, y}
    right_border = for y <- 0..(@height - 1), do: {@width - 1, y}
    top_border = for x <- 0..(@width - 1), do: {x, 0}
    bottom_border = for x <- 0..(@width - 1), do: {x, @height - 1}

    grid =
      for pos <- left_border ++ right_border ++ top_border ++ bottom_border,
          into: %{} do
        {pos, ColorBlock.new()}
      end
      |> Map.put({3, 0}, NoteBlock.new("x to create/destroy blocks, c to change block color, t to change block type, e to edit notes/links"))
      |> Map.put({4,0}, NoteBlock.new("Use WASD or the Arrow keys to move"))
      |> Map.put({5,0}, NoteBlock.new("The real deal is up next!"))
      |> Map.put({6,0}, LinkBlock.new("https://www.recurse.com/virtual2"))

    {:ok, %{players: %{}, grid: grid}}
  end

  @impl true
  def handle_call(
        {:register_player, name},
        {from_pid, _tag},
        %{players: players, grid: grid} = state
      ) do
    PlayerMonitor.monitor(from_pid)
    position = {3, 3}
    player = %Player{position: position, facing: :right, name: name, initial: "Q"}

    {:reply, player,
     %{
       state
       | players: Map.put(players, from_pid, player),
         grid: update_grid(grid, position, player)
     }}
  end

  def handle_call(
        {:unregister_player, player_pid},
        _from,
        %{players: players, grid: grid} = state
      )
      when is_map_key(players, player_pid) do
    {player, players} = Map.pop!(players, player_pid)
    grid = update_grid(grid, player.position, nil)

    {:reply, :ok,
     %{
       state
       | players: players,
         grid: grid
     }}
  end

  def handle_call(
        {:unregister_player, _player_pid},
        _from,
        _state
      ) do
    {:reply, {:error, "player not registered"}}
  end

  def handle_call(
        {:get_viewport, {x_origin, y_origin}, width, height},
        _from,
        %{grid: grid} = state
      ) do
    Logger.info("Getting viewport #{x_origin}, #{y_origin}")

    viewport =
      for {{x, y}, v} <- grid,
          x >= x_origin,
          y >= y_origin,
          x < x_origin + width,
          y < y_origin + height,
          into: %{},
          do: {{x, y}, v}

    {:reply, viewport, state}
  end

  def handle_call({:move, direction}, {from_pid, _tag}, %{grid: grid, players: players} = state)
      when is_map_key(players, from_pid) do
    {player, grid} =
      players[from_pid]
      |> move_player(direction, grid)

    players = Map.put(players, from_pid, player)

    {:reply, player, %{state | players: players, grid: grid}}
  end

  def handle_call({:move, _direction}, _from, state) do
    {:reply, {:error, "pid is not registered"}, state}
  end

  def handle_call(
        :create_or_destroy_block,
        {from_pid, _tag},
        %{grid: grid, players: players} = state
      )
      when is_map_key(players, from_pid) do
    %{position: {x, y}} = player = players[from_pid]
    Logger.info("create or destry")
    block_location =
      case player.facing do
        :up -> {x, y - 1}
        :down -> {x, y + 1}
        :left -> {x - 1, y}
        :right -> {x + 1, y}
      end

    grid =
      case grid[block_location] do
        # create a new block
        nil ->
          update_grid(grid, block_location, ColorBlock.new(player.last_color))

        # destroy the block
        %ColorBlock{} ->
          update_grid(grid, block_location, nil)

        # do nothing
        _ ->
          grid
      end

    {:reply, player, %{state | grid: grid}}
  end

  def handle_call(:create_or_destroy_block, _from, state) do
    {:reply, {:error, "pid is not registered"}, state}
  end

  def handle_call(
        :change_block_color,
        {from_pid, _tag},
        %{grid: grid, players: players} = state
      )
      when is_map_key(players, from_pid) do
    %{position: {x, y}} = player = players[from_pid]

    block_location =
      case player.facing do
        :up -> {x, y - 1}
        :down -> {x, y + 1}
        :left -> {x - 1, y}
        :right -> {x + 1, y}
      end

    {grid, player} =
      case grid[block_location] do
        # change the block color
        %ColorBlock{} = color_block ->
          new_block = ColorBlock.change_color(color_block)
          {update_grid(grid, block_location, new_block), %{player | last_color: new_block.color}}

        # do nothing
        _ ->
          {grid, player}
      end

    {:reply, player, %{state | grid: grid, players: Map.put(players, from_pid, player)}}
  end

  def handle_call(:change_block_color, _from, state) do
    {:reply, {:error, "pid is not registered"}, state}
  end

  defp move_player(
         %Player{position: {x, y} = initial_position, facing: direction} = player,
         direction,
         grid
       ) do
    Logger.info("Move #{direction}")

    position =
      case direction do
        :up when y > 1 -> {x, y - 1}
        :down when y < @height - 1 -> {x, y + 1}
        :left when x > 1 -> {x - 1, y}
        :right when x < @width - 1 -> {x + 1, y}
        _ -> initial_position
      end

    # didn't move
    if position == initial_position do
      {player, grid}
    else
      case grid[position] do
        # can't walk through blocks
        %ColorBlock{} ->
          {player, grid}

        # move
        _ ->
          player = %{player | position: position}

          grid =
            grid
            |> update_grid(initial_position, nil)
            |> update_grid(position, player)

          {player, grid}
      end
    end
  end

  defp move_player(player, direction, grid) do
    Logger.info("Turn #{direction}")

    player = %{player | facing: direction}
    grid = update_grid(grid, player.position, player)

    {player, grid}
  end

  defp update_grid(grid, position, nil) do
    Map.delete(grid, position)
    |> broadcast_update(position)
  end

  defp update_grid(grid, position, value) do
    Map.put(grid, position, value)
    |> broadcast_update(position)
  end

  defp broadcast_update(grid, position) do
    Phoenix.PubSub.broadcast(
      VirtualRcAlt.PubSub,
      @topic,
      {:update_cell, position, grid[position]}
    )

    grid
  end
end
