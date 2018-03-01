# coding: utf-8
require 'test/unit'
require_relative 'chess'

class TestChess < Test::Unit::TestCase
  def setup
    Rainbow.enabled = false  
    @chess = Chess.new
    $stdout = StringIO.new
    srand 1
  end

  def teardown
    $stdout = STDOUT
  end

  def test_10_moves
    @last_move = nil
    (1..10).each do |turn|
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
      6.g2g4
      6...d5xd2
      7.c1xd2
      7...c8xg4
      8.f2f4
      8...g4xe2
      9.e1xe2
      9...g7g5
      10.f4xg5
      10...a8c8
    TEXT
    assert_equal <<~TEXT, draw
      8 ♜ ♝ ♚♝♞♜
      7 ♟ ♟ ♟♟♟♟
      6
      5    ♛
      4
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
    # The white queen is developed too early. A black pawn seizes the
    # opportunity and attacks the queen. Looks lite a smart move, but it's just
    # dumb luck.
    assert_equal <<~TEXT, draw
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟  ♟
      6       ♟
      5      ♟ ♕
      4
      3     ♙
      2 ♙♙♙♙ ♙♙♙
      1 ♖♘♗ ♔♗♘♖
        abcdefgh
    TEXT

    move_white
    # The white queen follows the simple rule to always take when it's
    # possible, even though the black pawn is defended by another pawn.
    assert_equal <<~TEXT, draw
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟  ♟
      6       ♕
      5      ♟
      4
      3     ♙
      2 ♙♙♙♙ ♙♙♙
      1 ♖♘♗ ♔♗♘♖
        abcdefgh
    TEXT

    move_black
    # This other pawn follows the same rule and takes the queen.
    assert_equal <<~TEXT, draw
      8 ♜♞♝♛♚♝♞♜
      7 ♟♟♟♟♟
      6       ♟
      5      ♟
      4
      3     ♙
      2 ♙♙♙♙ ♙♙♙
      1 ♖♘♗ ♔♗♘♖
        abcdefgh
    TEXT

    move_white
    move_black
    # The black rook takes a pawn because it can, but leaves itself open to
    # retaliation.
    assert_equal <<~TEXT, draw
      8 ♜♞♝♛♚♝♞
      7 ♟♟♟♟♟
      6       ♟
      5      ♟
      4
      3     ♙  ♜
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

  def move_white
    @last_move = @chess.make_move(@turn += 1, :white)
  end

  def move_black
    @last_move = @chess.make_move(@turn, :black)
  end

  def draw
    convert(@chess.draw(@last_move))
  end

  def convert(s)
    s.gsub(/^(\d| ) (.)  (.)  (.)  (.)  (.)  (.)  (.)  (.) ?$/,
           '\1 \2\3\4\5\6\7\8\9')
     .gsub(/ +$/, '')
  end
end
