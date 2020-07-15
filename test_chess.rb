# coding: utf-8

# frozen_string_literal: true

require 'test/unit'
require_relative 'chess'

# Tests the methods in the Chess class.
class TestChess < Test::Unit::TestCase
  def setup
    Rainbow.enabled = false
    @brain = Brain.new
    @chess = Chess.new(@brain, show_taken_pieces: true)
    $stdout = StringIO.new
    srand 1
    @last_move = []
    @turn = 1
  end

  def teardown
    $stdout = STDOUT
  end

  def test_run_draw
    srand 8481
    assert_equal 'Draw due to threefold repetition', @chess.run
    assert_output_lines <<~TEXT
      35...h3g2
      8  ▒ ▒ ▒ ▒ | ♛♝♟♝♜♟♟♞♞♟♜♟♟
      7 ▒ ▒♕▒♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒♙▒♙▒♙▒╱
      2  ▒♙▒♙▒♚▒
      1 ▒ ▒ ♔ ▒  | ♙♙♖♙♖♗♗♘♘
        abcdefgh
      36.d7g4
      8  ▒ ▒ ▒ ▒ | ♛♝♟♝♜♟♟♞♞♟♜♟♟
      7 ▒ ▒╲▒♟♟
      6  ▒ ▒╲▒ ▒
      5 ▒ ▒ ▒╲▒
      4  ▒ ▒ ▒♕▒
      3 ▒♙▒♙▒♙▒
      2  ▒♙▒♙▒♚▒
      1 ▒ ▒ ♔ ▒  | ♙♙♖♙♖♗♗♘♘
        abcdefgh
    TEXT
  end

  def test_run_checkmate_size_4
    @chess = Chess.new(@brain, size: 4)
    assert_equal 'Checkmate', @chess.run
    assert_output_lines <<~TEXT
      4 ♜♛♚♜
      3 ♟♟♟♟
      2 ♙♙♙♙
      1 ♖♕♔♖
        abcd
      1.b2xa3
      4 ♜♛♚♜ | ♟
      3 ♙♟♟♟ # Not a smart move.
      2 ♙╲♙♙
      1 ♖♕♔♖
        abcd
      1...b4xa3
      4 ♜╱♚♜ | ♟
      3 ♛♟♟♟ # Queen takes pawn.
      2 ♙▒♙♙
      1 ♖♕♔♖ | ♙
        abcd
      2.b1b2
      4 ♜▒♚♜ | ♟
      3 ♛♟♟♟
      2 ♙♕♙♙ # The only possible move.
      1 ♖│♔♖ | ♙
        abcd
      2...a3xb2
      4 ♜▒♚♜ | ♟
      3 ╲♟♟♟
      2 ♙♛♙♙
      1 ♖ ♔♖ | ♙♕
        abcd
    TEXT
  end

  def test_run_fast_checkmate_size_4
    srand 9
    @chess = Chess.new(@brain, size: 4)
    assert_equal 'Checkmate', @chess.run
    assert_output_lines <<~TEXT
      4 ♜♛♚♜
      3 ♟♟♟♟
      2 ♙♙♙♙
      1 ♖♕♔♖
        abcd
      1.b2xa3
      4 ♜♛♚♜ ♟
      3 ♙♟♟♟
      2 ♙╲♙♙ # There's a possible checking move. Why was that not made?
      1 ♖♕♔♖
        abcd
      1...b4xa3
      4 ♜╱♚♜ ♟
      3 ♛♟♟♟ # Check.
      2 ♙ ♙♙
      1 ♖♕♔♖ ♙
        abcd
      2.b1b2
      4 ♜ ♚♜ ♟
      3 ♛♟♟♟
      2 ♙♕♙♙
      1 ♖│♔♖ ♙
        abcd
      2...a3xb2
      4 ♜ ♚♜ ♟
      3 ╲♟♟♟
      2 ♙♛♙♙ # Checkmate.
      1 ♖ ♔♖ ♙♕
        abcd
    TEXT
  end

  def test_run_checkmate_size_6
    srand 2
    @chess = Chess.new(@brain, size: 6)
    assert_equal 'Checkmate', @chess.run
    assert_output_lines <<~TEXT
      7...c6a4
      6  ▒╱♚♞♜ | ♟♜♟
      5 ▒╱♟♟♘
      4 ♛♟♞♙ ♟ # Bad move!
      3   ▒ ▒
      2 ♖▒♙▒♙♙
      1 ▒ ♕♔▒♖ | ♘♙♙
        abcdef
      8.a2xa4
      6  ▒ ♚♞♜ | ♟♜♟♛
      5 ▒ ♟♟♘
      4 ♖♟♞♙ ♟ # Rook takes queen.
      3 │ ▒ ▒
      2 │▒♙▒♙♙
      1 ▒ ♕♔▒♖ | ♘♙♙
        abcdef
      8...c4d2
      6  ▒ ♚♞♜ | ♟♜♟♛
      5 ▒ ♟♟♘
      4 ♖♟─♙ ♟
      3 ▒ ▒│▒
      2  ▒♙♞♙♙
      1 ▒ ♕♔▒♖ | ♘♙♙
        abcdef
      9.a4a6
      6 ♖▒ ♚♞♜ | ♟♜♟♛ # Checkmate.
      5 │ ♟♟♘
      4 │♟ ♙ ♟
      3 ▒ ▒ ▒
      2  ▒♙♞♙♙
      1 ▒ ♕♔▒♖ | ♘♙♙
        abcdef
    TEXT
  end

  def test_run_repetition_draw
    srand 41
    assert_equal 'Draw due to threefold repetition', @chess.run
    # Notice that only the white queen and the black king move in this
    # sequence leading up to the threefold repetition draw.
    assert_output_lines <<~TEXT
      13...a8xa7
      8 │▒♝▒♚♝ ♜ | ♞♞♟♛
      7 ♜ ♟ ♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒♟▒♟▒ ▒
      4  ♕ ♙ ♙ ♙
      3 ▒ ▒ ♗ ▒♖
      2  ♙♙▒♙♙ ▒
      1 ▒♘▒ ♔♗♘  | ♙♖
        abcdefgh
      14.b4xb5
      8  ▒♝▒♚♝ ♜ | ♞♞♟♛♟
      7 ♜ ♟ ♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒♕▒♟▒ ▒ # Check.
      4  │ ♙ ♙ ♙
      3 ▒ ▒ ♗ ▒♖
      2  ♙♙▒♙♙ ▒
      1 ▒♘▒ ♔♗♘  | ♙♖
        abcdefgh
      14...e8d8
      8  ▒♝♚─♝ ♜ | ♞♞♟♛♟
      7 ♜ ♟ ♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒♕▒♟▒ ▒
      4  ▒ ♙ ♙ ♙
      3 ▒ ▒ ♗ ▒♖
      2  ♙♙▒♙♙ ▒
      1 ▒♘▒ ♔♗♘  | ♙♖
        abcdefgh
      15.b5xd5
      8  ▒♝♚ ♝ ♜ | ♞♞♟♛♟♟
      7 ♜ ♟ ♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒──♕▒ ▒  # Check. 1st time black king and white queen on the d file.
      4  ▒ ♙ ♙ ♙ # This is the last time any piece is taken in the game.
      3 ▒ ▒ ♗ ▒♖
      2  ♙♙▒♙♙ ▒
      1 ▒♘▒ ♔♗♘  | ♙♖
        abcdefgh
      15...d8e8
      8   ♝─♚♝ ♜ | ♞♞♟♛♟♟
      7 ♜ ♟ ♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒ ▒♕▒ ▒
      4  ▒ ♙ ♙ ♙
      3 ▒ ▒ ♗ ▒♖
      2  ♙♙▒♙♙ ▒
      1 ▒♘▒ ♔♗♘  | ♙♖
        abcdefgh
      16.d5c6
      8  ▒♝▒♚♝ ♜ | ♞♞♟♛♟♟
      7 ♜ ♟ ♟♟♟
      6  ▒♕▒ ▒ ♟ # Check.
      5 ▒ ▒╲▒ ▒
      4  ▒ ♙ ♙ ♙
      3 ▒ ▒ ♗ ▒♖
      2  ♙♙▒♙♙ ▒
      1 ▒♘▒ ♔♗♘  | ♙♖
        abcdefgh
      16...e8d8
      8  ▒♝♚─♝ ♜ | ♞♞♟♛♟♟
      7 ♜ ♟ ♟♟♟
      6  ▒♕▒ ▒ ♟
      5 ▒ ▒ ▒ ▒
      4  ▒ ♙ ♙ ♙
      3 ▒ ▒ ♗ ▒♖
      2  ♙♙▒♙♙ ▒
      1 ▒♘▒ ♔♗♘  | ♙♖
        abcdefgh
      17.c6d5
      8  ▒♝♚ ♝ ♜ | ♞♞♟♛♟♟
      7 ♜ ♟ ♟♟♟
      6  ▒╲▒ ▒ ♟
      5 ▒ ▒♕▒ ▒ # Check. 2nd time black king and white queen on the d file.
      4  ▒ ♙ ♙ ♙
      3 ▒ ▒ ♗ ▒♖
      2  ♙♙▒♙♙ ▒
      1 ▒♘▒ ♔♗♘  | ♙♖
        abcdefgh
      17...d8e8
      8  ▒♝─♚♝ ♜ | ♞♞♟♛♟♟
      7 ♜ ♟ ♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒ ▒♕▒ ▒
      4  ▒ ♙ ♙ ♙
      3 ▒ ▒ ♗ ▒♖
      2  ♙♙▒♙♙ ▒
      1 ▒♘▒ ♔♗♘  | ♙♖
        abcdefgh
      18.d5b5
      8  ▒♝▒♚♝ ♜ | ♞♞♟♛♟♟
      7 ♜ ♟ ♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒♕──▒ ▒ # Check.
      4  ▒ ♙ ♙ ♙
      3 ▒ ▒ ♗ ▒♖
      2  ♙♙▒♙♙ ▒
      1 ▒♘▒ ♔♗♘  | ♙♖
        abcdefgh
      18...e8d8
      8  ▒♝♚─♝ ♜ | ♞♞♟♛♟♟
      7 ♜ ♟ ♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒♕▒ ▒ ▒
      4  ▒ ♙ ♙ ♙
      3 ▒ ▒ ♗ ▒♖
      2  ♙♙▒♙♙ ▒
      1 ▒♘▒ ♔♗♘  | ♙♖
        abcdefgh
      19.b5d5
      8  ▒♝♚ ♝ ♜ | ♞♞♟♛♟♟
      7 ♜ ♟ ♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒──♕▒ ▒ # Check. 3rd time black king and white queen on the d file.
      4  ▒ ♙ ♙ ♙
      3 ▒ ▒ ♗ ▒♖
      2  ♙♙▒♙♙ ▒
      1 ▒♘▒ ♔♗♘  | ♙♖
        abcdefgh
    TEXT
  end

  def test_run_checkmate
    # Fastest possible checkmate win for black.
    srand 49
    assert_equal 'Checkmate', @chess.run
    assert_output_lines <<~TEXT
      1.f2f3
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒♙▒
      2 ♙♙♙♙♙│♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
      1...e7e5
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟│♟♟♟
      6  ▒ ▒│▒ ▒
      5 ▒ ▒ ♟ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒♙▒
      2 ♙♙♙♙♙▒♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
      2.g2g4
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟▒♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ♟ ▒
      4  ▒ ▒ ▒♙▒
      3 ▒ ▒ ▒♙│
      2 ♙♙♙♙♙▒│♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
      2...d8h4
      8 ♜♞♝╲♚♝♞♜
      7 ♟♟♟♟╲♟♟♟
      6  ▒ ▒ ╲▒
      5 ▒ ▒ ♟ ╲
      4  ▒ ▒ ▒♙♛
      3 ▒ ▒ ▒♙▒
      2 ♙♙♙♙♙▒ ♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
  end

  def test_run_stalemate
    setup_board <<~TEXT
      8  ▒ ▒ ▒ ♔
      7 ▒ ▒ ▒♚▒
      6  ▒ ▒ ▒♛▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
    TEXT
    assert_equal 'Stalemate', @chess.run
  end

  def test_5_moves
    @last_move = nil
    (1..5).each do |turn|
      @chess.make_move(turn, :white)
      @last_move = @chess.make_move(turn, :black)
    end
    assert_equal <<~TEXT, $stdout.string
      1.c2c4
      1...e7e5
      2.d1a4
      2...g8e7
      3.a4xa7
      3...a8xa7
      4.h2h3
      4...a7xa2
      5.a1xa2
      5...f7f5
    TEXT
    assert_board <<~TEXT
      8  ♞♝♛♚♝ ♜ | ♟♜
      7 ▒♟♟♟♞ ♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ♟♟▒
      4  ▒♙▒ ▒ ▒
      3 ▒ ▒ ▒ ▒♙
      2 ♖♙ ♙♙♙♙▒
      1 ▒♘♗▒♔♗♘♖ | ♕♙
        abcdefgh
    TEXT
  end

  def test_a_few_moves_detailed
    srand 2
    @last_move = nil
    @turn = 0

    2.times do
      move_white
      move_black
    end
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟ ♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒ ▒♟▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ♙ ▒♙
      2 ♙♙♙♙ ♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT

    move_white
    # Two pawn moves each, then white's light square bishop follows the simple
    # rule to check when it's possible.
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟ ♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒♗▒♟▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ♙ ▒♙
      2 ♙♙♙♙ ♙♙▒
      1 ♖♘♗♕♔ ♘♖
        abcdefgh
    TEXT

    move_black
    # Black blocks the check with a bishop.
    assert_board <<~TEXT
      8 ♜♞ ♛♚♝♞♜
      7 ♟♟♟♝♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒♗▒♟▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ♙ ▒♙
      2 ♙♙♙♙ ♙♙▒
      1 ♖♘♗♕♔ ♘♖
        abcdefgh
    TEXT

    move_white
    # White moves its light square bishop back to its starting position.
    assert_board <<~TEXT
      8 ♜♞ ♛♚♝♞♜
      7 ♟♟♟♝♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒ ▒♟▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ♙ ▒♙
      2 ♙♙♙♙ ♙♙▒
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT

    move_black
    # A pretty useless move for the black queen.
    assert_board <<~TEXT
      8 ♜♞♛ ♚♝♞♜
      7 ♟♟♟♝♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒ ▒♟▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ♙ ▒♙
      2 ♙♙♙♙ ♙♙▒
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT

    assert_equal <<~TEXT, $stdout.string
      1.e2e3
      1...h7h6
      2.h2h3
      2...d7d5
      3.f1b5
      3...c8d7
      4.b5f1
      4...d8c8
    TEXT
  end

  def test_a_few_other_moves_detailed
    @chess = Chess.new(@brain, show_taken_pieces: false)
    srand 3
    @last_move = nil
    @turn = 0

    2.times do
      move_white
      move_black
    end
    # White starts with two pawn moves, black with knights.
    assert_board <<~TEXT
      8 ♜▒♝♛♚♝ ♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒♞▒ ♞ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ♙ ▒ ▒
      3 ▒ ▒ ▒♙▒
      2 ♙♙♙▒♙▒♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT

    move_white
    # Then a knight from white.
    assert_board <<~TEXT
      8 ♜▒♝♛♚♝ ♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒♞▒ ♞ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ♙ ▒ ▒
      3 ▒ ▒ ▒♙▒♘
      2 ♙♙♙▒♙▒♙♙
      1 ♖♘♗♕♔♗▒♖
        abcdefgh
    TEXT

    move_black
    # And black knight takes a pawn.
    assert_board <<~TEXT
      8 ♜▒♝♛♚♝ ♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ♞ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ♞ ▒ ▒
      3 ▒ ▒ ▒♙▒♘
      2 ♙♙♙▒♙▒♙♙
      1 ♖♘♗♕♔♗▒♖
        abcdefgh
    TEXT

    move_white
    move_black
    # White develops its queen too early, and black pushes another pawn.
    assert_board <<~TEXT
      8 ♜▒♝♛♚♝ ♜
      7 ▒♟♟♟♟♟♟♟
      6  ▒ ▒ ♞ ▒
      5 ♟ ▒ ▒ ▒
      4  ▒ ♕ ▒ ▒
      3 ▒ ▒ ▒♙▒♘
      2 ♙♙♙▒♙▒♙♙
      1 ♖♘♗ ♔♗▒♖
        abcdefgh
    TEXT

    assert_equal <<~TEXT, $stdout.string
      1.f2f3
      1...g8f6
      2.d2d4
      2...b8c6
      3.g1h3
      3...c6xd4
      4.d1xd4
      4...a7a5
    TEXT
  end

  def test_setup
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    new_position = clean(<<~TEXT)
      8 ♜♞♝♛♚♝♞
      7 ♟♟♟♟♟ ▒
      6  ▒ ▒ ▒♟▒
      5 ▒ ▒ ▒♟▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ♙ ▒♜
      2 ♙♙♙♙ ♙♙
      1 ♖♘♗ ♔♗♘♖
        abcdefgh
    TEXT
    @chess.setup(new_position)
    assert_equal new_position, draw
  end

  def test_white_takes_en_passant
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟ ♟
      6  ▒ ▒ ♟ ♟
      5 ▒ ▒ ▒ ▒♙
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙▒
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟ ▒
      6  ▒ ▒ ♟ ♟
      5 ▒ ▒ ▒ ♟♙
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙▒
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    move_white
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜ | ♟
      7 ♟♟♟♟♟ ▒
      6  ▒ ▒ ♟♙♟
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙▒
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
  end

  def test_black_takes_en_passant
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟ ♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ♟ ▒
      3 ▒ ▒ ▒♙▒♙
      2 ♙♙♙♙♙▒♙▒
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟ ♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ♟♙▒
      3 ▒ ▒ ▒♙▒♙
      2 ♙♙♙♙♙▒ ▒
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    move_black
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟ ♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒♙♟♙
      2 ♙♙♙♙♙▒ ▒
      1 ♖♘♗♕♔♗♘♖ | ♙
        abcdefgh
    TEXT
  end

  def test_too_late_for_en_passant
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒♙
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙▒
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟▒♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ♟♙
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙▒
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟▒♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ♟♙
      4  ▒ ▒♙▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙ ♙♙▒
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    move_black
    move_white
    # Taking the black pawn en passant is only allowed immediately after the
    # black pawn takes two steps forward. In this case white has made another
    # move in-between, so it can't take the black pawn.
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7  ♟♟♟♟♟▒♟
      6  ▒ ▒ ▒ ▒
      5 ♟ ▒ ▒ ♟♙
      4  ▒ ▒♙▒ ▒
      3 ▒ ♘ ▒ ▒
      2 ♙♙♙♙ ♙♙▒
      1 ♖ ♗♕♔♗♘♖
        abcdefgh
    TEXT
  end

  def test_wrong_rank_for_en_passant
    setup_board <<~TEXT
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ♟
      6  ▒ ▒ ▒ ♙
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
    TEXT
    setup_board <<~TEXT
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒ ▒♟♙
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
    TEXT
    move_white
    # Black only moved one step, so taking en passant is not allowed. White
    # makes the ony possible move.
    assert_board <<~TEXT
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒♙
      6  ▒ ▒ ▒♟▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
    TEXT
  end

  def test_white_castles_on_king_side
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔ ▒♖
        abcdefgh
    TEXT
    move_white
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕▒♖♔
        abcdefgh
    TEXT
  end

  def test_white_castles_on_queen_side
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖ ▒ ♔♗♘♖
        abcdefgh
    TEXT
    move_white
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ▒ ♔♖▒♗♘♖
        abcdefgh
    TEXT
  end

  def test_black_castles_on_king_side
    setup_board <<~TEXT
      8 ♜♞♝♛♚▒ ♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    move_black
    assert_board <<~TEXT
      8 ♜♞♝♛ ♜♚▒
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
  end

  def test_black_castles_on_queen_side
    setup_board <<~TEXT
      8 ♜▒ ▒♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    move_black
    assert_board <<~TEXT
      8  ▒♚♜ ♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
  end

  def test_white_cannot_castle_due_to_check
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞▒
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ♜ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙ ♙♙♙
      1 ♖ ▒ ♔ ▒♖
        abcdefgh
    TEXT
    move_white
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞▒
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ♜ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙ ♙♙♙
      1 ♖ ▒ ▒♔▒♖
        abcdefgh
    TEXT
  end

  def test_black_cannot_castle_due_to_check
    setup_board <<~TEXT
      8 ♜▒ ▒♚▒ ♜
      7 ♟♟♟♟ ♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒♖▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔♗♘
        abcdefgh
    TEXT
    move_black
    assert_board <<~TEXT
      8 ♜▒ ▒ ♚ ♜
      7 ♟♟♟♟ ♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒♖▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔♗♘
        abcdefgh
    TEXT
  end

  def test_white_cannot_castle_due_to_empty_squares_being_attacked
    setup_board <<~TEXT
      8  ♞♝♛♚♝♞▒
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒♜ ♜▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙▒♙▒♙♙
      1 ♖ ▒ ♔ ▒♖
        abcdefgh
    TEXT
    move_white
    assert_board <<~TEXT
      8  ♞♝♛♚♝♞▒
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒♜ ♜▒
      4  ▒♙▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙ ▒♙▒♙♙
      1 ♖ ▒ ♔ ▒♖
        abcdefgh
    TEXT
  end

  def test_black_cannot_castle_due_to_empty_squares_being_attacked
    setup_board <<~TEXT
      8 ♜▒ ▒♚▒ ♜
      7 ♟♟♟ ♟ ♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ♖ ♖ ▒
      3 ▒ ▒ ▒ ▒
      2  ♙♙♙♙♙♙▒
      1 ▒♘♗♕♔♗♘
        abcdefgh
    TEXT
    move_black
    assert_board <<~TEXT
      8 ♜▒ ▒♚▒ ♜
      7 ♟ ♟ ♟ ♟♟
      6  ♟ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ♖ ♖ ▒
      3 ▒ ▒ ▒ ▒
      2  ♙♙♙♙♙♙▒
      1 ▒♘♗♕♔♗♘
        abcdefgh
    TEXT
  end

  def test_white_cannot_castle_because_its_king_has_moved
    board = Board.new
    @chess = Chess.new(@brain, board: board)
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖ ▒ ▒♔▒♖
        abcdefgh
    TEXT
    move('f1e1', board)
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖ ▒ ♔─▒♖
        abcdefgh
    TEXT
    move_white
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒♙▒ ▒ ▒
      3 ▒ │ ▒ ▒
      2 ♙♙│♙♙♙♙♙
      1 ♖ ▒ ♔ ▒♖
        abcdefgh
    TEXT
  end

  def test_black_cannot_castle_because_its_king_has_moved
    board = Board.new
    @chess = Chess.new(@brain, board: board)
    setup_board <<~TEXT
      8 ♜▒ ▒♚▒ ♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    move('e8f8', board)
    move('f8e8', board) # King has now moved to f8 and back.
    move_black
    assert_board <<~TEXT
      8 ♜▒ ▒♚▒♜─ # Moves rook. Does not castle.
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
  end

  def test_white_cannot_castle_because_rooks_have_moved
    srand 2
    board = Board.new
    @chess = Chess.new(@brain, board: board)
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖ ▒ ♔  ♖
        abcdefgh
    TEXT
    move('h1g1', board)
    move('g1h1', board)
    move('a1b1', board)
    move('b1a1', board)
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖ ▒ ♔ ▒♖
        abcdefgh
    TEXT
    move_white
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ♙ ▒  # Does not castle.
      2 ♙♙♙♙│♙♙♙
      1 ♖ ▒ ♔ ▒♖
        abcdefgh
    TEXT
  end

  def test_black_cannot_castle_because_rooks_have_moved
    srand 2
    board = Board.new
    @chess = Chess.new(@brain, board: board)
    setup_board <<~TEXT
      8 ♜▒ ▒♚▒ ♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    move('a8b8', board)
    move('b8a8', board)
    move('h8g8', board)
    move('g8h8', board)
    assert_board <<~TEXT
      8 ♜▒ ▒♚▒ ♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    move_black
    assert_board <<~TEXT
      8 ♜▒ ▒♚▒ ♜
      7 │♟♟♟♟♟♟♟
      6 │▒ ▒ ▒ ▒
      5 ♟ ▒ ▒ ▒  # Does not castle.
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
  end

  def test_human_interaction
    # The first move is legal, the second one is wrong format, the third is
    # correct format but not a legal move. The user will be prompted
    # for a correct move, which the last one is.
    $stdin = StringIO.new(<<~TEXT)
      e2e4
      ee3
      e1e3
      e1e2
    TEXT
    @chess.get_human_move(1)
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒♙▒ ▒
      3 ▒ ▒ │ ▒
      2 ♙♙♙♙│♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    move_black
    @chess.get_human_move(2)
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟│♟
      6  ▒ ▒ ▒♟▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒♙▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♔♙♙♙
      1 ♖♘♗♕│♗♘♖
        abcdefgh
    TEXT
    assert_equal <<~TEXT.chomp, $stdout.string
      White move: 1.1...g7g6
      White move: 2.Illegal move
      White move: 2.Illegal move
      White move: 2.
    TEXT
  end

  # TODO: A bad move is made by the black queen. It should be avoided.
  def test_avoid_dangerous_move
    @chess = Chess.new(@brain, board: Board.new)
    setup_board <<~TEXT
      8 ♜♞♝ ♚♝♞♜
      7 ♟♟ ♟♟♟♟♟
      6  ▒♟▒ ▒ ▒
      5 ♛ ▒ ▒ ▒
      4  ▒ ♙♙▒ ▒
      3 ▒ ♙ ▒ ▒
      2 ♙♙ ▒ ♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    move_black
    assert_output_lines "1...a5xa2\n"
    assert_board <<~TEXT
      8 ♜♞♝▒♚♝♞♜
      7 ♟♟▒♟♟♟♟♟
      6  ▒♟▒ ▒ ▒
      5 │ ▒ ▒ ▒
      4 │▒ ♙♙▒ ▒
      3 │ ♙ ▒ ▒
      2 ♛♙ ▒ ♙♙♙ # Bad move!
      1 ♖♘♗♕♔♗♘♖ | ♙
        abcdefgh
    TEXT
    move_white
    assert_output_lines <<~TEXT
      1...a5xa2
      2.a1xa2
    TEXT
    assert_board <<~TEXT
      8 ♜♞♝▒♚♝♞♜ | ♛
      7 ♟♟▒♟♟♟♟♟
      6  ▒♟▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ♙♙▒ ▒
      3 ▒ ♙ ▒ ▒
      2 ♖♙ ▒ ♙♙♙
      1 │♘♗♕♔♗♘♖ | ♙
        abcdefgh
    TEXT
  end

  def test_choose_a_good_move
    setup_board <<~TEXT
      8  ▒ ♖ ▒ ▒
      7 ▒ ♟ ▒♚▒
      6  ♟♞♟♖♟♟♞
      5 ▒ ▒ ▒ ▒♟
      4  ♙ ♙ ▒ ▒
      3 ▒ ▒ ▒♘♗
      2  ▒ ▒ ♙♙♙
      1 ▒ ▒ ♕ ♔
        abcdefgh
    TEXT
    move_black
    # The black knight at c6 kan take one of two pawns or a rook. It should
    # choose the rook.
    assert_board <<~TEXT
      8  ▒┌♞ ▒ ▒
      7 ▒ ♟ ▒♚▒
      6  ♟│♟♖♟♟♞
      5 ▒ ▒ ▒ ▒♟
      4  ♙ ♙ ▒ ▒
      3 ▒ ▒ ▒♘♗
      2  ▒ ▒ ♙♙♙
      1 ▒ ▒ ♕ ♔  | ♖
        abcdefgh
    TEXT
  end

  def test_regression_of_en_passant_handling
    setup_board <<~TEXT
      8 ♜▒ ▒♚ ♞♜
      7 ▒ ▒ ▒ ♟
      6 ♟♟ ♟ ▒ ▒
      5 ▒ ▒ ♙♟▒♟
      4 ♙♙ ▒ ▒♝♙
      3 ♞ ♙ ▒ ▒
      2  ▒♖♙ ♕ ▒
      1 ▒ ♔ ▒ ▒
        abcdefgh
    TEXT
    move_white
    assert_board <<~TEXT
      8 ♜▒ ▒♚▒♞♜ | ♟
      7 ▒ ▒ ▒ ♟
      6 ♟♕ ♟ ▒ ▒
      5 ▒ ╲ ♙♟ ♟
      4 ♙♙ ╲ ▒♝♙
      3 ♞ ♙ ╲ ▒
      2  ▒♖♙ ╲ ▒
      1 ▒ ♔ ▒ ▒
        abcdefgh
    TEXT
  end

  def test_board_size
    assert_equal '6', board_size('CHESS_SIZE' => '6')
    assert_equal 8, board_size({})
  end

  def test_computer_opponent
    assert_true Stockfish === computer_opponent(%w[-s])
    assert_true Brain === computer_opponent(%w[-h])
  end

  def test_main_fen_setup
    fen = '8/8/k7/8/4R1QB/8/8/8 w - - 0 1'
    result = @chess.main(['-f', fen])
    assert_output_lines <<~TEXT
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6 ♚▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒♖▒♕♗
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
      1.g4e2
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6 ♚▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒♖▒╱♗
      3 ▒ ▒ ▒╱▒
      2  ▒ ▒♕▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
      1...a6a5
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6 │▒ ▒ ▒ ▒
      5 ♚ ▒ ▒ ▒
      4  ▒ ▒♖▒ ♗
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒♕▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
      2.h4d8
      8  ▒ ♗ ▒ ▒
      7 ▒ ▒ ╲ ▒
      6  ▒ ▒ ╲ ▒
      5 ♚ ▒ ▒ ╲
      4  ▒ ▒♖▒ ╲
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒♕▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
      Checkmate
    TEXT
  end

  def test_main_fen_setup_insufficient_material
    fen = '8/8/k7/7K/8/8/8/8 w - - 0 1'
    result = @chess.main(['-f', fen])
    assert_output_lines <<~TEXT
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6 ♚▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒♔▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
      Draw due to insufficient material
    TEXT
  end

  def test_main_fen_setup_human_player
    $stdin = StringIO.new(<<~TEXT)
      g4e2
      h4d8
    TEXT
    fen = '8/8/k7/8/4R1QB/8/8/8 w - - 0 1'
    result = @chess.main(['-f', fen, '-h'])
    assert_output_lines <<~TEXT
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6 ♚▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒♖▒♕♗
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
      White move: 1.8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6 ♚▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒♖▒╱♗
      3 ▒ ▒ ▒╱▒
      2  ▒ ▒♕▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
      1...a6a5
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6 │▒ ▒ ▒ ▒
      5 ♚ ▒ ▒ ▒
      4  ▒ ▒♖▒ ♗
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒♕▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
      White move: 2.8        ▒ ♗
      7 ▒ ▒ ╲ ▒
      6  ▒ ▒ ╲ ▒
      5 ♚ ▒ ▒ ╲
      4  ▒ ▒♖▒ ╲
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒♕▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
      Checkmate
    TEXT
  end

  def test_main_human_playing_badly
    srand 4
    # The human player just moves the knight back and forth the whole game.
    $stdin = StringIO.new(<<~INPUT * 11)
      b1c3
      c3b1
    INPUT
    @chess.main(['-h'])
    assert_output_lines <<~TEXT
      21...h1xf1
      8  ♞♚♜ ▒♞♜ | ♝
      7 ▒ ▒♟▒ ♟♟
      6  ♟ ▒♟▒ ▒
      5 ♟ ♟ ▒♟▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ♘ ▒ ▒
      2 ♙♙♙♙♙♙♝▒
      1 ♖ ♗♕♔♛── | ♙♖♘♙♗
        abcdefgh
      Checkmate
    TEXT
  end

  def test_legal_move
    assert_true @chess.legal?('e2e4')
    assert_false @chess.legal?('e2e9')
  end

  private def move_white
    @last_move = @chess.make_move(@turn += 1, :white)
  end

  private def move_black
    @last_move = @chess.make_move(@turn, :black)
  end

  private def setup_board(text)
    @chess.setup(clean(text))
  end

  private def assert_board(text)
    assert_equal clean(text), draw
  end

  private def assert_output_lines(text)
    assert_equal clean(text),
                 convert($stdout.string.lines.last(text.lines.length).join)
  end

  private def draw
    convert(@chess.draw(@last_move))
  end

  private def convert(board_output)
    board_output
      .gsub(/^(\d| ) (.)  (.)  (.)  (.)(?:  (.)  (.))?(?:  (.)  (.))? ?/,
            '\1 \2\3\4\5\6\7\8\9')
      .gsub(/ +$/, '')
  end

  private def clean(board_setup)
    board_setup.tr('▒│─╱╲┌┐└┘', '         ').gsub(/ +$/, '').gsub('| ', '')
               .gsub(/ *#.*/, '')
  end

  private def move(notation, board)
    board.move(*Coord.from_move(board, notation))
  end
end
