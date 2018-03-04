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
    @board.move(6, 4, 5, 4)
    assert_equal ['♜♞♝♛♚♝♞♜',
                  '♟♟♟♟♟♟♟♟',
                  '        ',
                  '        ',
                  '        ',
                  '    ♙   ',
                  '♙♙♙♙ ♙♙♙',
                  '♖♘♗♕♔♗♘♖'], @board.current
    new_board = Board.new(@board)
    new_board.move(5, 4, 4, 4)
    assert_equal ['♜♞♝♛♚♝♞♜',
                  '♟♟♟♟♟♟♟♟',
                  '        ',
                  '        ',
                  '    ♙   ',
                  '        ',
                  '♙♙♙♙ ♙♙♙',
                  '♖♘♗♕♔♗♘♖'], new_board.current
    assert_not_equal @board.current, new_board.current
    @board.move(5, 4, 4, 4)
    assert_equal @board.current, new_board.current
  end

  def test_en_passant
    @board.move(6, 5, 3, 5)
    assert_equal ['♜♞♝♛♚♝♞♜',
                  '♟♟♟♟♟♟♟♟',
                  '        ',
                  '     ♙  ',
                  '        ',
                  '        ',
                  '♙♙♙♙♙ ♙♙',
                  '♖♘♗♕♔♗♘♖'], @board.current
    @board.move(1, 6, 3, 6)
    assert_equal ['♜♞♝♛♚♝♞♜',
                  '♟♟♟♟♟♟ ♟',
                  '        ',
                  '     ♙♟ ',
                  '        ',
                  '        ',
                  '♙♙♙♙♙ ♙♙',
                  '♖♘♗♕♔♗♘♖'], @board.current
    @board.move(3, 5, 2, 6)
    assert_equal ['♜♞♝♛♚♝♞♜',
                  '♟♟♟♟♟♟ ♟',
                  '      ♙ ',
                  '        ',
                  '        ',
                  '        ',
                  '♙♙♙♙♙ ♙♙',
                  '♖♘♗♕♔♗♘♖'], @board.current
  end

  def test_wrong_piece_for_en_passant
    @board.move(7, 3, 3, 5)
    assert_equal ['♜♞♝♛♚♝♞♜',
                  '♟♟♟♟♟♟♟♟',
                  '        ',
                  '     ♕  ',
                  '        ',
                  '        ',
                  '♙♙♙♙♙♙♙♙',
                  '♖♘♗ ♔♗♘♖'], @board.current
    @board.move(1, 6, 3, 6)
    assert_equal ['♜♞♝♛♚♝♞♜',
                  '♟♟♟♟♟♟ ♟',
                  '        ',
                  '     ♕♟ ',
                  '        ',
                  '        ',
                  '♙♙♙♙♙♙♙♙',
                  '♖♘♗ ♔♗♘♖'], @board.current
    @board.move(3, 5, 2, 6)
    assert_equal ['♜♞♝♛♚♝♞♜',
                  '♟♟♟♟♟♟ ♟',
                  '      ♕ ',
                  '      ♟ ',
                  '        ',
                  '        ',
                  '♙♙♙♙♙♙♙♙',
                  '♖♘♗ ♔♗♘♖'], @board.current
  end

  def test_white_castles_on_king_side
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒ ♔ ▒♖
        abcdefgh
    TEXT
    @board.move(7, 4, 7, 6)
    assert_equal ['        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '     ♖♔ '], @board.current
  end

  def test_white_castles_on_queen_side
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ♖ ▒ ♔ ▒
        abcdefgh
    TEXT
    @board.move(7, 4, 7, 2)
    assert_equal ['        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '  ♔♖    '], @board.current
  end

  def test_black_castles_on_king_side
    @board.setup(<<~TEXT)
      8  ▒ ▒♚▒ ♜
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
    TEXT
    @board.move(0, 4, 0, 6)
    assert_equal ['     ♜♚ ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        '], @board.current
  end

  def test_black_castles_on_queen_side
    @board.setup(<<~TEXT)
      8 ♜▒ ▒♚▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
    TEXT
    @board.move(0, 4, 0, 2)
    assert_equal ['  ♚♜    ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        '], @board.current
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
    assert_true @board.outside_board?(8, 3)
    assert_true @board.outside_board?(-1, 3)
    assert_true @board.outside_board?(0, -1)
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

  def test_move_and_previous
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

  def test_colors
    @board.move(6, 4, 5, 4)
    Rainbow.enabled = true
    assert_equal <<~TEXT, @board.draw([6, 4, 5, 4])
      8#{wh'♜'}#{bk'♞'}#{wh'♝'}#{bk'♛'}#{wh'♚'}#{bk'♝'}#{wh'♞'}#{bk'♜'}
      7#{bk'♟'}#{wh'♟'}#{bk'♟'}#{wh'♟'}#{bk'♟'}#{wh'♟'}#{bk'♟'}#{wh'♟'}
      6#{wh' '}#{bk' '}#{wh' '}#{bk' '}#{wh' '}#{bk' '}#{wh' '}#{bk' '}
      5#{bk' '}#{wh' '}#{bk' '}#{wh' '}#{bk' '}#{wh' '}#{bk' '}#{wh' '}
      4#{wh' '}#{bk' '}#{wh' '}#{bk' '}#{wh' '}#{bk' '}#{wh' '}#{bk' '}
      3#{bk' '}#{wh' '}#{bk' '}#{wh' '}#{yl'♙'}#{wh' '}#{bk' '}#{wh' '}
      2#{wh'♙'}#{bk'♙'}#{wh'♙'}#{bk'♙'}#{yl' '}#{bk'♙'}#{wh'♙'}#{bk'♙'}
      1#{bk'♖'}#{wh'♘'}#{bk'♗'}#{wh'♕'}#{bk'♔'}#{wh'♗'}#{bk'♘'}#{wh'♖'}
        a  b  c  d  e  f  g  h
    TEXT
  end

  def wh(piece)
    "\e[48;5;231m\e[30m #{piece} \e[0m"
  end

  def bk(piece)
    "\e[48;5;188m\e[30m #{piece} \e[0m"
  end

  def yl(piece)
    "\e[43m\e[30m #{piece} \e[0m"
  end

  def test_setup
    @board.setup(<<~TEXT)
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
    assert_equal ['        ',
                  '        ',
                  '    ♚   ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '   ♔    '], @board.current
    assert_equal ['♜♞♝♛♚♝♞♜',
                  '♟♟♟♟♟♟♟♟',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '♙♙♙♙♙♙♙♙',
                  '♖♘♗♕♔♗♘♖'], @board.previous.current
  end

  def test_only_kings_left
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒♚▒ ▒
      5 ▒ ▒ ♙ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒♔▒ ▒
        abcdefgh
    TEXT
    assert_false @board.only_kings_left?
    @board.move(2, 4, 3, 4)
    assert_true @board.only_kings_left?
  end

  def test_white_pawn_promotion
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒♙▒
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
    TEXT
    @board.move(1, 5, 0, 5)
    assert_equal ['     ♕  ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        '], @board.current
  end

  def test_black_pawn_promotion
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ♟ ▒
      1 ▒ ▒ ▒ ▒
        abcdefgh
    TEXT
    @board.move(6, 5, 7, 5)
    assert_equal ['        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '     ♛  '], @board.current
  end

  def test_incomplete_board_setup
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒♚▒ ▒
      5 ▒ ▒
      4  ▒ 
    TEXT
    assert_equal ['        ',
                  '        ',
                  '    ♚   ',
                  '        ',
                  '        ',
                  '        ',
                  '        ',
                  '        '], @board.current
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
