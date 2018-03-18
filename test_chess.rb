# coding: utf-8

# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

require 'test/unit'
require_relative 'chess'

# Tests the methods in the Chess class.
class TestChess < Test::Unit::TestCase
  def setup
    Rainbow.enabled = false
    @brain = Brain.new
    @chess = Chess.new(@brain)
    $stdout = StringIO.new
    srand 1
    @last_move = []
    @turn = 1
  end

  def teardown
    $stdout = STDOUT
  end

  # After updating the brain algorithm to avoid moving to attacked squares, a
  # queen plus two kings never result in a draw, and it's possible that we
  # don't get the "only two kings left" kind of draws anymore.
  def disabled_test_run_draw
    assert_equal 'Draw', @chess.run
    assert_output_lines 10, <<~TEXT
      69.g2xg3
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒ ▒♚▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ♔
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
    TEXT
  end

  def test_run_repetition_draw
    srand 14
    assert_equal 'Draw due to threefold repetition', @chess.run
    assert_output_lines 10, <<~TEXT
      8...h5h4
      8 ♜♞♝▒♚♝♞♜
      7 ♟♟♟♟▒♟♟♟
      6  ▒ ▒♟▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ♙ ♛
      3 ▒ ▒ ♙ ▒
      2 ♙♙♙♙ ♔♙♙
      1 ♖♘♗♕▒♗♘♖
        abcdefgh
    TEXT
  end

  def test_run_checkmate
    # Fastest possible checkmate win for black.
    srand 49
    assert_equal 'Checkmate', @chess.run
    assert_output_lines 30, <<~TEXT
      1...e7e5
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟▒♟♟♟
      6  ▒ ▒ ▒ ▒
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
      3 ▒ ▒ ▒♙▒
      2 ♙♙♙♙♙▒ ♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
      2...d8h4
      8 ♜♞♝▒♚♝♞♜
      7 ♟♟♟♟▒♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ♟ ▒
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
      3.a4c2
      3...f7f6
      4.c2b3
      4...h7h6
      5.b3xb7
      5...c8xb7
    TEXT
    assert_board <<~TEXT
      8 ♜♞ ♛♚♝ ♜
      7 ♟♝♟♟♞ ♟
      6      ♟ ♟
      5     ♟
      4   ♙
      3
      2 ♙♙ ♙♙♙♙♙
      1 ♖♘♗ ♔♗♘♖
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
    # Black chooses randomly among the moves that removes the check. It's not a
    # good one, sacrificing the queen.
    assert_board <<~TEXT
      8 ♜♞♝▒♚♝♞♜
      7 ♟♟♟♛♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒♗▒♟▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ♙ ▒♙
      2 ♙♙♙♙ ♙♙▒
      1 ♖♘♗♕♔ ♘♖
        abcdefgh
    TEXT

    move_white
    move_black
    assert_board <<~TEXT
      8 ♜♞♝▒♚♝♞♜
      7 ♟♟♟ ♟♟♟
      6  ▒ ▒ ▒ ♟
      5 ▒♛▒♟▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ♙♙▒♙
      2 ♙♙♙♙  ♙
      1 ♖♘♗♕♔ ♘♖
        abcdefgh
    TEXT

    assert_equal <<~TEXT, $stdout.string
      1.e2e3
      1...h7h6
      2.h2h3
      2...d7d5
      3.f1b5
      3...d8d7
      4.f2f3
      4...d7xb5
    TEXT
  end

  def test_a_few_other_moves_detailed
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
      8 ♜♞♝♛♚♝♞♜
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
      1 ♖♘♗♕♔♗♘♖
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
    @chess = Chess.new(@brain, board)
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
    board.move(Coord.new(7, 5), Coord.new(7, 4))
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
      4  ▒♙▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙ ♙♙♙♙♙
      1 ♖ ▒ ♔ ▒♖
        abcdefgh
    TEXT
  end

  def test_black_cannot_castle_because_its_king_has_moved
    board = Board.new
    @chess = Chess.new(@brain, board)
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
    board.move(Coord.new(0, 4), Coord.new(0, 5))
    board.move(Coord.new(0, 5), Coord.new(0, 4))
    move_black
    assert_board <<~TEXT
      8 ♜▒ ▒♚▒♜▒
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
    @chess = Chess.new(@brain, board)
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
    board.move(Coord.new(7, 7), Coord.new(7, 6))
    board.move(Coord.new(7, 6), Coord.new(7, 7))
    board.move(Coord.new(7, 0), Coord.new(7, 1))
    board.move(Coord.new(7, 1), Coord.new(7, 0))
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
      3 ▒ ▒ ♙ ▒
      2 ♙♙♙♙ ♙♙♙
      1 ♖ ▒ ♔ ▒♖
        abcdefgh
    TEXT
  end

  def test_black_cannot_castle_because_rooks_have_moved
    srand 2
    board = Board.new
    @chess = Chess.new(@brain, board)
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
    board.move(Coord.new(0, 0), Coord.new(0, 1))
    board.move(Coord.new(0, 1), Coord.new(0, 0))
    board.move(Coord.new(0, 7), Coord.new(0, 6))
    board.move(Coord.new(0, 6), Coord.new(0, 7))
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
      7 ▒♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ♟ ▒ ▒ ▒
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
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙ ♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    move_black
    @chess.get_human_move(2)
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟ ♟
      6  ▒ ▒ ▒♟▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒♙▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♔♙♙♙
      1 ♖♘♗♕▒♗♘♖
        abcdefgh
    TEXT
    assert_equal <<~TEXT.chomp, $stdout.string
      White move: 1.1...g7g6
      White move: 2.Illegal move
      White move: 2.Illegal move
      White move: 2.
    TEXT
  end

  def test_avoid_dangerous_move
    board = Board.new
    @chess = Chess.new(@brain, board)
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
    assert_board <<~TEXT
      8 ♜♞♝ ♚♝♞♜
      7 ♟♟ ♟♟ ♟♟
      6  ▒♟▒ ▒ ▒
      5 ♛ ▒ ▒♟▒
      4  ▒ ♙♙▒ ▒
      3 ▒ ♙ ▒ ▒
      2 ♙♙ ▒ ♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
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

  private def assert_output_lines(nr_of_lines, text)
    assert_equal clean(text),
                 convert($stdout.string.lines.last(nr_of_lines).join)
  end

  private def draw
    convert(@chess.draw(@last_move))
  end

  private def convert(board_output)
    board_output.gsub(/^(\d| ) (.)  (.)  (.)  (.)  (.)  (.)  (.)  (.) ?$/,
                      '\1 \2\3\4\5\6\7\8\9')
                .gsub(/ +$/, '')
  end

  private def clean(board_setup)
    board_setup.tr('▒', ' ').gsub(/ +$/, '')
  end
end

# rubocop:enable Metrics/MethodLength
