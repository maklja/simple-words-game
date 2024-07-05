defmodule WordGameServer do
  use GenServer

  @hidden_field "*"

  def start_link(game_id, game_words, registry) do
    name = {:via, Registry, {registry, game_id}}
    GenServer.start_link(__MODULE__, game_words, name: name)
  end

  def get_state(pid) when is_pid(pid) do
    GenServer.call(pid, :state)
  end

  def guess_word(pid, player_name, guess) when is_pid(pid) do
    GenServer.call(pid, {:play, player_name, guess})
  end

  @impl true
  def init(game_words) do
    hidden_words = hide_words(game_words, [])

    {:ok, %{words: Enum.zip(game_words, hidden_words), score_board: Map.new()}}
  end

  @impl true
  def handle_call(:state, _from, state) do
    %{words: words, score_board: score_board} = state

    hidden_words = Enum.map(words, &elem(&1, 1))
    {:reply, %{words: hidden_words, score_board: score_board}, state}
  end

  @impl true
  def handle_call({:play, player_name, guess}, _from, state) do
    new_state = play_guess_word(player_name, guess, state)
    new_player_score = Map.fetch!(new_state.score_board, player_name)

    if has_game_finished?(new_state) do
      {:reply, {:game_over, new_state.score_board}, new_state}
    else
      {:reply, {:play, player_name, new_player_score}, new_state}
    end
  end

  defp has_game_finished?(%{words: words}),
    do: Enum.all?(words, fn {word, hidden_word} -> word === hidden_word end)

  defp play_guess_word(player_name, guess, state) do
    %{words: words, score_board: score_board} = state

    result = match_words(guess, words, [])

    full_match =
      Enum.find(result, nil, fn
        {_, {:full, _, _}} -> true
        _ -> false
      end)

    {total_score, new_words} =
      if full_match !== nil do
        {words, {:full, score, word}} = full_match

        new_words =
          Enum.map(result, fn
            {old_words, _} when old_words === words -> {word, word}
            {old_words, _} -> old_words
          end)

        {score, new_words}
      else
        cal_new_words(result, [], 0)
      end

    new_score_board =
      Map.update(score_board, player_name, total_score, fn player_score ->
        player_score + total_score
      end)

    state |> Map.put(:words, new_words) |> Map.put(:score_board, new_score_board)
  end

  defp cal_new_words([], new_words_list, total_score),
    do: {total_score, Enum.reverse(new_words_list)}

  defp cal_new_words([match_result | rem_results], new_words_list, total_score) do
    {words, match_result} = match_result
    {score, new_words} = calc_new_word(words, match_result)

    cal_new_words(rem_results, [new_words | new_words_list], total_score + score)
  end

  defp calc_new_word(words, :error), do: {0, words}

  defp calc_new_word(words, {:done, score, _}), do: {score, words}

  defp calc_new_word({word, _}, {:partial, score, hidden_word}), do: {score, {word, hidden_word}}

  defp match_words(_, [], results), do: Enum.reverse(results)

  defp match_words(guess, [words | rem_words], results) do
    {word, hidden_word} = words

    result = match_word(guess, word, hidden_word)
    match_words(guess, rem_words, [{words, result} | results])
  end

  defp match_word(guess, word, _) when byte_size(guess) !== byte_size(word), do: :error

  defp match_word(_, word, word), do: {:done, 0, word}

  defp match_word(guess, word, hidden_word) do
    word_chars = String.graphemes(word)
    hidden_word_chars = String.graphemes(hidden_word)
    guess_chars = String.graphemes(guess)

    word_match_result =
      Enum.zip_with([word_chars, hidden_word_chars, guess_chars], fn
        [c, c, c] -> {0, c}
        [c, c, _] -> :error
        [c, @hidden_field, c] -> {1, c}
        [_, @hidden_field, _] -> {0, @hidden_field}
      end)

    result =
      Enum.reduce(word_match_result, {0, ""}, fn
        {point, char}, {score, word} ->
          {score + point, word <> char}

        :error, {_, _} ->
          :error

        _, _ ->
          :error
      end)

    case result do
      :error ->
        :error

      {score, word} ->
        if String.contains?(word, @hidden_field),
          do: {:partial, score, word},
          else: {:full, 10, word}
    end
  end

  defp hide_words([], hidden_words), do: Enum.reverse(hidden_words)

  defp hide_words([word | rem_words], hidden_words) do
    rnd_idx = :rand.uniform(String.length(word) - 1)

    hidden_word =
      create_hidden_fields(rnd_idx) <>
        String.at(word, rnd_idx) <> create_hidden_fields(String.length(word) - rnd_idx - 1)

    hide_words(rem_words, [hidden_word | hidden_words])
  end

  defp create_hidden_fields(n), do: String.duplicate(@hidden_field, n)
end
