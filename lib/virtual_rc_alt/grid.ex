defmodule VirtualRcAlt.Grid do
  use GenServer
  require Logger

  alias VirtualRcAlt.{Player, ColorBlock, NoteBlock, LinkBlock, PlayerMonitor}

  @width 50
  @height 50
  @spawn_point {3,3}

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

  def create_or_destroy_block(position), do: create_or_destroy_block(__MODULE__, position)

  def create_or_destroy_block(pid, position),
    do: GenServer.call(pid, {:create_or_destroy_block, position})

  def change_block_color(position), do: change_block_color(__MODULE__, position)
  def change_block_color(pid, position), do: GenServer.call(pid, {:change_block_color, position})

  def change_block_type(position), do: change_block_type(__MODULE__, position)
  def change_block_type(pid, position), do: GenServer.call(pid, {:change_block_type, position})

  def edit_block(position, content), do: edit_block(__MODULE__, position, content)

  def edit_block(pid, position, content),
    do: GenServer.call(pid, {:edit_block, position, content})

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
      |> Map.put(
        {3, 0},
        NoteBlock.new(
          "x to create/destroy blocks, c to change block color, t to change block type, e to edit notes/links"
        )
      )
      |> Map.put({4, 0}, NoteBlock.new("Use WASD or the Arrow keys to move"))
      |> Map.put({5, 0}, NoteBlock.new("The real deal is up next!"))
      |> Map.put({6, 0}, LinkBlock.new("https://www.recurse.com/virtual2"))

    {:ok, %{players: %{}, grid: grid}}
  end

  @impl true
  def handle_call(
        {:register_player, name},
        {from_pid, _tag},
        %{players: players, grid: grid} = state
      ) do
    PlayerMonitor.monitor(from_pid)

    player = %Player{
      pid: from_pid,
      position: @spawn_point,
      facing: :right,
      name: name,
      initial: (String.first(name) || "?") |> String.upcase()
    }

    {:reply, player,
     %{
       state
       | players: Map.put(players, from_pid, player),
         grid: update_grid(grid, @spawn_point, [player | get_cell(grid, @spawn_point)])
     }}
  end

  def handle_call(
        {:unregister_player, player_pid},
        _from,
        %{players: players, grid: grid} = state
      )
      when is_map_key(players, player_pid) do
    {player, players} = Map.pop!(players, player_pid)
    grid = update_grid(grid, player.position, [])

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

  # no touching the spawn point
  def handle_call(
        {:create_or_destroy_block, @spawn_point},
        _from,
        state
      ),
      do: {:reply, :ok, state}

  def handle_call(
        {:create_or_destroy_block, position},
        {from_pid, _tag},
        %{grid: grid, players: players} = state
      )
      when is_map_key(players, from_pid) do
    player = players[from_pid]

    grid =
      case get_cell(grid, position) do
        # create a new block
        [] ->
          update_grid(grid, position, ColorBlock.new(player.last_color))

        # destroy the block
        %ColorBlock{} ->
          update_grid(grid, position, nil)

        # do nothing
        _ ->
          grid
      end

    {:reply, :ok, %{state | grid: grid}}
  end

  def handle_call({:create_or_destroy_block, _position}, _from, state) do
    {:reply, {:error, "pid is not registered"}, state}
  end

  def handle_call(
        {:change_block_color, position},
        {from_pid, _tag},
        %{grid: grid, players: players} = state
      )
      when is_map_key(players, from_pid) do
    player = players[from_pid]

    case get_cell(grid, position) do
      # change the block color
      %ColorBlock{} = color_block ->
        new_block = ColorBlock.change_color(color_block)
        grid = update_grid(grid, position, new_block)
        player = %{player | last_color: new_block.color}
        players = Map.put(players, from_pid, player)

        {:reply, :ok, %{state | grid: grid, players: Map.put(players, from_pid, player)}}

      # do nothing
      _ ->
        {:reply, :ok, state}
    end
  end

  def handle_call({:change_block_color, _position}, _from, state) do
    {:reply, {:error, "pid is not registered"}, state}
  end

  def handle_call(
        {:change_block_type, position},
        {from_pid, _tag},
        %{grid: grid, players: players} = state
      )
      when is_map_key(players, from_pid) do
    grid =
      case get_cell(grid, position) do
        %ColorBlock{} ->
          update_grid(grid, position, NoteBlock.new())

        %NoteBlock{} ->
          update_grid(grid, position, LinkBlock.new())

        %LinkBlock{} ->
          update_grid(grid, position, ColorBlock.new())

        _ ->
          grid
      end

    {:reply, :ok, %{state | grid: grid}}
  end

  def handle_call({:create_or_destroy_block, _position}, _from, state) do
    {:reply, {:error, "pid is not registered"}, state}
  end

  def handle_call({:edit_block, position, content}, _from, %{grid: grid} = state) do
    grid =
      case block = get_cell(grid, position) do
        %NoteBlock{} -> update_grid(grid, position, %{block | note: content})
        %LinkBlock{} -> update_grid(grid, position, %{block | url: content})
        _ -> block
      end

    {:reply, :ok, %{state | grid: grid}}
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
      case get_cell(grid, position) do
        # can't walk through blocks
        %ColorBlock{} ->
          {player, grid}

        %NoteBlock{} ->
          {player, grid}

        %LinkBlock{} ->
          {player, grid}

        # move
        _ ->
          # TODO this is hacky with the list thing, should be a pipeline with better named helpers!
          new_player = %{player | position: position}

          grid =
            update_grid(
              grid,
              initial_position,
              List.delete(get_cell(grid, initial_position), player)
            )

          grid =
            update_grid(grid, position, [
              new_player | get_cell(grid, position)
            ])

          {new_player, grid}
      end
    end
  end

  defp move_player(%Player{position: position} = player, direction, grid) do
    Logger.info("Turn #{direction}")

    # TODO this is hacky with the list thing, should be a pipeline with better named helpers!
    new_player = %{player | facing: direction}

    grid =
      update_grid(grid, position, [new_player | List.delete(get_cell(grid, position), player)])

    {new_player, grid}
  end

  def get_cell(grid, position) do
    Map.get(grid, position, [])
  end

  def update_grid(grid, position, []) do
    Map.delete(grid, position)
    |> broadcast_update(position, [])
  end

  def update_grid(grid, position, value) do
    Map.put(grid, position, value)
    |> broadcast_update(position, value)
  end

  defp broadcast_update(grid, position, value) do
    Logger.info("Updaing #{inspect(position)}")

    Phoenix.PubSub.broadcast(
      VirtualRcAlt.PubSub,
      @topic,
      {:update_cell, position, value}
    )

    grid
  end
end
