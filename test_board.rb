# coding: utf-8
require 'test/unit'
require_relative 'board'

class TestBoard < Test::Unit::TestCase
  def setup
    @board = Board.new
    Rainbow.enabled = false
  end

  def test_initialization
    assert_equal ['♜♞♝♛♚♝♞♜',
                  '♟♟♟♟♟♟♟♟',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '♙♙♙♙♙♙♙♙',
                  '♖♘♗♕♔♗♘♖'], @board.current
  end

  def test_cloning
    new_board = Board.new(@board)
    @board.move(6, 4, 5, 4)
    assert_equal ['♜♞♝♛♚♝♞♜',
                  '♟♟♟♟♟♟♟♟',
                  '        ',
                  '        ',
                  '        ',
                  '    ♙   ',
                  '♙♙♙♙ ♙♙♙',
                  '♖♘♗♕♔♗♘♖'], @board.current
    assert_not_equal @board.current, new_board.current
    new_board.move(6, 4, 5, 4)
    assert_equal @board.current, new_board.current
  end

  def test_get
    assert_equal '♜', @board.get(0, 0)
  end

  def test_empty
    assert_false @board.empty?(0, 0)
    assert_true @board.empty?(3, 3)
  end

  def test_outside_board
    assert_false @board.outside_board?(0, 0)
    assert_true @board.outside_board?(3, 8)
  end

  def test_color_at_predicate
    assert_true @board.color_at?(:black, 0, 0)
    assert_true @board.color_at?(:white, 7, 0)
  end

  def test_color_at
    assert_equal :black, @board.color_at(0, 0)
    assert_equal :white, @board.color_at(7, 0)
  end

  def test_taking
    @board.move(6, 0, 2, 0) # Illegal move, but there's no checking.
    assert_true @board.taking?(2, 0, 1, 1)
  end

  def test_draw
    assert_equal(("8 ♜  ♞  ♝  ♛  ♚  ♝  ♞  ♜ \n" +
                  "7 ♟  ♟  ♟  ♟  ♟  ♟  ♟  ♟ \n" +
                  "6                        \n" +
                  "5                        \n" +
                  "4                        \n" +
                  "3                        \n" +
                  "2 ♙  ♙  ♙  ♙  ♙  ♙  ♙  ♙ \n" +
                  "1 ♖  ♘  ♗  ♕  ♔  ♗  ♘  ♖ \n" +
                  "  a  b  c  d  e  f  g  h\n"), @board.draw)
  end

  def test_king_is_taken_by
    @board.move(7, 4, 2, 4)
    assert_true @board.king_is_taken_by?(['d7xe6'])
    assert_true @board.king_is_taken_by?(['f7xe6'])
    assert_false @board.king_is_taken_by?(['f7xh6'])
  end

  def test_previous
    @board.move(6, 4, 5, 4)
    assert_equal ['♜♞♝♛♚♝♞♜',
                  '♟♟♟♟♟♟♟♟',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '♙♙♙♙♙♙♙♙',
                  '♖♘♗♕♔♗♘♖'], @board.previous.current
  end
end
