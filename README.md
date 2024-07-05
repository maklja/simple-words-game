# Simple Word Game

Project created to practice and improve Elixir programming skills. This game challenges players to guess words based on given hints.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Gameplay](#gameplay)
- [License](#license)

## Installation

To get started with the Simple Word Game, you'll need to have Elixir installed on your machine. Follow the instructions below to set up the project:

1. **Clone the repository:**

   ```sh
   git clone https://github.com/maklja/simple-words-game.git
   ```

2. **Navigate to the project directory:**

   ```sh
   cd simple-word-game
   ```

3. **Install dependencies:**

   ```sh
   mix deps.get
   ```

4. **Compile the project:**

   ```sh
   mix compile
   ```

## Usage

To start the application and to create new game:

```bash
iex --sname game -S mix

game_id = WordGameApplication.create_game()
```

Follow the on-screen instructions to create a set of words that players need to guess. 
Other players can connect and play the game using the following commands

```bash
iex --remsh game --sname player_node

WordGameApplication.guess_word(game_id, "player", "my guess")

WordGameApplication.print_game_state(game_id)
```

## Gameplay

In the Simple Word Game, players are presented with a set of hidden words. The goal is to guess the correct word based on the hints provided and collect points. Here’s how to play:

- Each letter is worth one point.
- Full word guess worth 10 points.
- There are not turns, player can guess as many time he wants.
- Player with most points wins in the end.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.