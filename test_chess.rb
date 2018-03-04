# coding: utf-8
require 'test/unit'
require_relative 'chess'

class TestChess < Test::Unit::TestCase
  def setup
    Rainbow.enabled = false  
    @chess = Chess.new
    $stdout = StringIO.new
    srand 1
    @last_move = []
  end

  def teardown
    $stdout = STDOUT
  end

  def test_run_draw
    srand 4
    assert_equal 'Draw', @chess.run
    assert_output_lines 10, <<~TEXT
      62...f7xe6
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒♚▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒♔▒ ▒
        abcdefgh
    TEXT
  end

  def test_run_repetition_draw
    srand 9
    assert_equal 'Draw due to threefold repetition', @chess.run
    assert_output_lines 10, <<~TEXT
      43.f2e1
      8  ▒ ▒ ▒ ▒
      7 ♚ ▒ ♟ ▒
      6  ▒ ▒♙▒ ▒
      5 ▒ ▒ ♙ ▒
      4  ▒ ▒ ▒ ♟
      3 ▒ ▒ ▒ ▒♙
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒ ♔ ▒
        abcdefgh
    TEXT
  end

  def test_run_checkmate
    srand 390
    assert_equal 'Checkmate', @chess.run
    assert_output_lines 30, <<~TEXT
      3.d1h5
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟ ♟
      6  ▒ ▒ ▒ ♟
      5 ▒ ▒ ▒♟▒♕
      4  ▒ ▒♙▒ ▒
      3 ▒ ♙ ▒ ▒
      2 ♙♙ ♙ ♙♙♙
      1 ♖♘♗ ♔♗♘♖
        abcdefgh
      3...g7g6
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟ ▒
      6  ▒ ▒ ▒♟♟
      5 ▒ ▒ ▒♟▒♕
      4  ▒ ▒♙▒ ▒
      3 ▒ ♙ ▒ ▒
      2 ♙♙ ♙ ♙♙♙
      1 ♖♘♗ ♔♗♘♖
        abcdefgh
      4.h5xg6
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟ ▒
      6  ▒ ▒ ▒♕♟
      5 ▒ ▒ ▒♟▒
      4  ▒ ▒♙▒ ▒
      3 ▒ ♙ ▒ ▒
      2 ♙♙ ♙ ♙♙♙
      1 ♖♘♗ ♔♗♘♖
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
      1...d7d5
      2.d1a4
      2...b7b5
      3.a4xb5
      3...b8d7
      4.b5xd7
      4...d8xd7
      5.c4xd5
      5...d7xd5
    TEXT
    assert_board <<~TEXT
      8 ♜▒♝▒♚♝♞♜
      7 ♟ ♟ ♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒♛▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
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
    # The white queen is developed too early. A black pawn seizes the
    # opportunity and attacks the queen. Looks lite a smart move, but it's just
    # dumb luck.
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟ ▒♟
      6  ▒ ▒ ▒♟▒
      5 ▒ ▒ ▒♟▒♕
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ♙ ▒
      2 ♙♙♙♙ ♙♙♙
      1 ♖♘♗ ♔♗♘♖
        abcdefgh
    TEXT

    move_white
    # The white queen follows the simple rule to always take when it's
    # possible, even though the black pawn is defended by another pawn.
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟ ▒♟
      6  ▒ ▒ ▒♕▒
      5 ▒ ▒ ▒♟▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ♙ ▒
      2 ♙♙♙♙ ♙♙♙
      1 ♖♘♗ ♔♗♘♖
        abcdefgh
    TEXT

    move_black
    # This other pawn follows the same rule and takes the queen.
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟ ▒
      6  ▒ ▒ ▒♟▒
      5 ▒ ▒ ▒♟▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ♙ ▒
      2 ♙♙♙♙ ♙♙♙
      1 ♖♘♗ ♔♗♘♖
        abcdefgh
    TEXT

    move_white
    move_black
    # The black rook takes a pawn because it can, but leaves itself open to
    # retaliation.
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞▒
      7 ♟♟♟♟♟ ▒
      6  ▒ ▒ ▒♟▒
      5 ▒ ▒ ▒♟▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ♙ ▒♜
      2 ♙♙♙♙ ♙♙
      1 ♖♘♗ ♔♗♘♖
        abcdefgh
    TEXT

    assert_equal <<~TEXT, $stdout.string
      1.e2e3
      1...f7f5
      2.d1h5
      2...g7g6
      3.h5xg6
      3...h7xg6
      4.h2h3
      4...h8xh3
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
    @turn = 1
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
    move_white
    assert_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟▒♟
      6  ▒ ▒ ▒♙▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙▒
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
  end

  def test_black_takes_en_passant
    @turn = 1
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟ ♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ♟ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟ ♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ♟♙▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙ ♙
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
      3 ▒ ▒ ▒ ♟
      2 ♙♙♙♙♙♙ ♙
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
  end

  def test_too_late_for_en_passant
    @turn = 1
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
      8 ♜♞♝♛♚♝ ♜
      7 ♟♟♟♟♟♟▒♟
      6  ▒ ▒ ♞ ▒
      5 ▒ ▒ ▒ ♟♙
      4  ▒ ▒♙♙ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙ ▒♙▒
      1 ♖♘♗♕♔♗♘♖
        abcdefgh
    TEXT
  end

  def test_wrong_rank_for_en_passant
    @turn = 1
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
    @turn = 1
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖♘♗♕♔  ♖
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
      1 ♖♘♗♕ ♖♔
        abcdefgh
    TEXT
  end

  def test_white_castles_on_queen_side
    @turn = 1
    setup_board <<~TEXT
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟♟♟♟
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2 ♙♙♙♙♙♙♙♙
      1 ♖   ♔♗♘♖
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
      1   ♔♖ ♗♘♖
        abcdefgh
    TEXT
  end

  def test_black_castles_on_king_side
    @turn = 1
    setup_board <<~TEXT
      8 ♜♞♝♛♚  ♜
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
      8 ♜♞♝♛ ♜♚
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
    @turn = 1
    setup_board <<~TEXT
      8 ♜   ♚♝♞♜
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
      8   ♚♜ ♝♞♜
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

  private def convert(s)
    s.gsub(/^(\d| ) (.)  (.)  (.)  (.)  (.)  (.)  (.)  (.) ?$/,
           '\1 \2\3\4\5\6\7\8\9')
     .gsub(/ +$/, '')
  end

  private def clean(s)
    s.gsub('▒', ' ').gsub(/ +$/, '')
  end
end
