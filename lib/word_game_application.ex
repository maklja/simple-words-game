defmodule WordGameApplication do
  use Application

  @moduledoc """
  Words game application.
  """

  @doc """
  Words game application.

  ## Examples

      bash> iex --sname game -S mix

      iex> game_id = WordGameApplication.create_game()

      iex> WordGameApplication.print_game_state(game_id)

      iex> WordGameApplication.guess_word(game_id, "player", "my guess")

      bash> iex --remsh game --sname other_player_node
  """
  @impl true
  def start(_type, _args) do
    {:ok, _} = Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def create_game() do
    # generate "unique" id
    game_id = :rand.uniform(1_000_000) |> to_string()

    all_words = load_words()
    game_words = create_game_words([], all_words)

    Supervisor.start_link(
      [
        %{
          id: WordGameServer,
          start: {WordGameServer, :start_link, [game_id, game_words, __MODULE__]}
        }
      ],
      strategy: :one_for_one
    )

    game_id
  end

  def print_game_state(game_id) when is_binary(game_id) do
    [{game_pid, _}] = Registry.lookup(__MODULE__, game_id)
    game_state = WordGameServer.get_state(game_pid)
    print_score_board(game_state.score_board)
    IO.puts("\n")
    print_words(game_state.words)
  end

  def guess_word(game_id, player_name, word) when is_binary(player_name) and is_binary(word) do
    [{game_pid, _}] = Registry.lookup(__MODULE__, game_id)

    case WordGameServer.guess_word(game_pid, player_name, word) do
      {:game_over, score_board} ->
        players_score =
          score_board
          |> Enum.sort(fn {_, score1}, {_, score2} -> score1 >= score2 end)
          |> Enum.take(2)

        print_winner(players_score)
        IO.puts("\n")
        print_score_board(score_board)

      {:play, player_name, new_player_score} ->
        IO.puts("#{player_name}, your new score is #{new_player_score}\n")
        game_state = WordGameServer.get_state(game_pid)
        print_score_board(game_state.score_board)
        IO.puts("\n")
        print_words(game_state.words)
    end
  end

  defp print_words(words) when is_list(words),
    do:
      Enum.each(words, fn word ->
        IO.puts("#{word}")
      end)

  defp print_score_board(score_board) when is_map(score_board),
    do:
      Enum.each(score_board, fn {player_name, score} ->
        IO.puts("#{player_name} ----- #{score}")
      end)

  defp print_winner([player]), do: print_winner(player)

  defp print_winner([{_, score1} = player1, {_, score2} = player2]) do
    cond do
      score1 === score2 -> IO.puts("No winner, the game is tied!")
      score1 > score2 -> print_winner(player1)
      true -> print_winner(player2)
    end
  end

  defp print_winner({player_name, score}),
    do: IO.puts("Winner is #{player_name} with a score #{score}")

  defp create_game_words([], %MapSet{} = all_words) do
    case get_input_word() do
      "" -> create_game_words([], all_words)
      word -> create_game_words([word], all_words)
    end
  end

  defp create_game_words([head | _] = words, %MapSet{} = all_words) do
    new_word = get_input_word()

    cond do
      new_word === "" ->
        Enum.reverse(words)

      not MapSet.member?(all_words, new_word) ->
        IO.puts("The word is not allowed")
        create_game_words(words, all_words)

      byte_size(new_word) === byte_size(head) ->
        create_game_words([new_word | words], all_words)

      true ->
        IO.puts("The word must be length #{byte_size(head)}")
        create_game_words(words, all_words)
    end
  end

  defp get_input_word(), do: IO.gets("Please enter hidden word?\n") |> String.replace("\n", "")

  defp load_words() do
    words_file_path = Path.join(:code.priv_dir(:words_game), ~c"words.txt")

    words_file_path
    |> File.stream!()
    |> Stream.map(&String.replace(&1, "\n", ""))
    |> MapSet.new()
  end
end
