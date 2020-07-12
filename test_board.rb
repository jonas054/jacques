# coding: utf-8

# frozen_string_literal: true

require 'test/unit'
require_relative 'board'

# Tests the methods in the Board class.
class TestBoard < Test::Unit::TestCase
  def setup
    @board = Board.new
    Rainbow.enabled = false
  end

  def test_fen
    @board
      .setup_fen 'r1b2rk1/pp1p1pp1/1b1p2B1/n1qQ2p1/8/5N2/P3RPPP/4R1K1 w - - 0 1'
    assert_current <<~TEXT
      ♜▒♝▒ ♜♚▒
      ♟♟▒♟▒♟♟
       ♝ ♟ ▒♗▒
      ♞ ♛♕▒ ♟
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒♘▒
      ♙▒ ▒♖♙♙♙
      ▒ ▒ ♖ ♔
    TEXT
    assert_equal 'r1b2rk1/pp1p1pp1/1b1p2B1/n1qQ2p1/8/5N2/P3RPPP/4R1K1',
                 @board.fen
  end

  def test_initialization
    assert_current <<~TEXT
      ♜♞♝♛♚♝♞♜
      ♟♟♟♟♟♟♟♟
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
      ♙♙♙♙♙♙♙♙
      ♖♘♗♕♔♗♘♖
    TEXT
  end

  def test_cloning
    move('e2e3')
    assert_current <<~TEXT
      ♜♞♝♛♚♝♞♜
      ♟♟♟♟♟♟♟♟
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ♙ ▒
      ♙♙♙♙ ♙♙♙
      ♖♘♗♕♔♗♘♖
    TEXT
    new_board = Board.new(original: @board)
    move('e3e4', new_board)
    assert_equal ['♜♞♝♛♚♝♞♜',
                  '♟♟♟♟♟♟♟♟',
                  '        ',
                  '        ',
                  '    ♙   ',
                  '        ',
                  '♙♙♙♙ ♙♙♙',
                  '♖♘♗♕♔♗♘♖'], new_board.current
    assert_not_equal @board.current, new_board.current
    move('e3e4')
    assert_equal @board.current, new_board.current
  end

  def test_en_passant
    move('f2f5')
    assert_current <<~TEXT
      ♜♞♝♛♚♝♞♜
      ♟♟♟♟♟♟♟♟
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒♙▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
      ♙♙♙♙♙ ♙♙
      ♖♘♗♕♔♗♘♖
    TEXT
    move('g7g5')
    assert_current <<~TEXT
      ♜♞♝♛♚♝♞♜
      ♟♟♟♟♟♟ ♟
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒♙♟
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
      ♙♙♙♙♙ ♙♙
      ♖♘♗♕♔♗♘♖
    TEXT
    move('f5g6')
    assert_current <<~TEXT
      ♜♞♝♛♚♝♞♜
      ♟♟♟♟♟♟ ♟
       ▒ ▒ ▒♙▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
      ♙♙♙♙♙ ♙♙
      ♖♘♗♕♔♗♘♖
    TEXT
  end

  def test_wrong_piece_for_en_passant
    move('d1f5')
    assert_current <<~TEXT
      ♜♞♝♛♚♝♞♜
      ♟♟♟♟♟♟♟♟
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒♕▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
      ♙♙♙♙♙♙♙♙
      ♖♘♗ ♔♗♘♖
    TEXT
    move('g7g5')
    assert_current <<~TEXT
      ♜♞♝♛♚♝♞♜
      ♟♟♟♟♟♟ ♟
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒♕♟
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
      ♙♙♙♙♙♙♙♙
      ♖♘♗ ♔♗♘♖
    TEXT
    move('f5g6')
    assert_current <<~TEXT
      ♜♞♝♛♚♝♞♜
      ♟♟♟♟♟♟ ♟
       ▒ ▒ ▒♕▒
      ▒ ▒ ▒ ♟
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
      ♙♙♙♙♙♙♙♙
      ♖♘♗ ♔♗♘♖
    TEXT
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
    move('e1g1')
    assert_current <<~TEXT
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒♖♔
    TEXT
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
    move('e1c1')
    assert_current <<~TEXT
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ♔♖▒ ▒
    TEXT
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
    move('e8g8')
    assert_current <<~TEXT
       ▒ ▒ ♜♚▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
    TEXT
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
    move('e8c8')
    assert_current <<~TEXT
       ▒♚♜ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
    TEXT
  end

  def test_get
    assert_equal '♜', @board.get(Coord.new(@board, 0, 0))
  end

  def test_empty
    assert_false @board.empty?(Coord.new(@board, 0, 0))
    assert_true @board.empty?(Coord.new(@board, 3, 3))
  end

  def test_outside_board
    assert_false Coord.new(@board, 0, 0).outside_board?
    assert_true Coord.new(@board, 3, 8).outside_board?
    assert_true Coord.new(@board, 8, 3).outside_board?
    assert_true Coord.new(@board, -1, 3).outside_board?
    assert_true Coord.new(@board, 0, -1).outside_board?
  end

  def test_color_at
    assert_equal :black, @board.color_at(Coord.new(@board, 0, 0))
    assert_equal :white, @board.color_at(Coord.new(@board, 7, 0))
  end

  def test_taking
    # Illegal move, but there's no checking.
    move('a2a6')
    assert_current <<~TEXT
      ♜♞♝♛♚♝♞♜
      ♟♟♟♟♟♟♟♟
      ♙▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ♙♙♙♙♙♙♙
      ♖♘♗♕♔♗♘♖
    TEXT
    assert_true @board.taking?(*Coord.from_move(@board, 'a6b7'))
  end

  def test_draw
    assert_equal("8 ♜  ♞  ♝  ♛  ♚  ♝  ♞  ♜ \n" \
                 "7 ♟  ♟  ♟  ♟  ♟  ♟  ♟  ♟ \n" \
                 "6                        \n" \
                 "5                        \n" \
                 "4                        \n" \
                 "3                        \n" \
                 "2 ♙  ♙  ♙  ♙  ♙  ♙  ♙  ♙ \n" \
                 "1 ♖  ♘  ♗  ♕  ♔  ♗  ♘  ♖ \n" \
                 "  a  b  c  d  e  f  g  h\n", @board.draw)
  end

  def test_king_is_taken_by
    @rule_book = RuleBook.new(@board)
    @board.move(Coord.new(@board, 7, 4), Coord.new(@board, 2, 4))
    assert_true @rule_book.king_is_taken_by?(['d7xe6'])
    assert_true @rule_book.king_is_taken_by?(['f7xe6'])
    assert_false @rule_book.king_is_taken_by?(['f7xh6'])
  end

  def test_move_and_previous
    @board.move(Coord.new(@board, 6, 4), Coord.new(@board, 5, 4))
    assert_previous <<~TEXT
      ♜♞♝♛♚♝♞♜
      ♟♟♟♟♟♟♟♟
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
      ♙♙♙♙♙♙♙♙
      ♖♘♗♕♔♗♘♖
    TEXT
  end

  def test_colors
    @board.move(Coord.new(@board, 6, 4), Coord.new(@board, 5, 4))
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
    assert_current <<~TEXT
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒♚▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒♔▒ ▒
    TEXT
    assert_previous <<~TEXT
      ♜♞♝♛♚♝♞♜
      ♟♟♟♟♟♟♟♟
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
      ♙♙♙♙♙♙♙♙
      ♖♘♗♕♔♗♘♖
    TEXT
  end

  def test_insufficient_material_only_kings
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
    assert_false @board.insufficient_material?
    @board.move(Coord.new(@board, 2, 4), Coord.new(@board, 3, 4))
    assert_true @board.insufficient_material?
  end

  def test_insufficient_material_kings_and_a_white_bishop
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒♚▒ ▒
      5 ▒ ▒ ♗ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒♔▒ ▒
        abcdefgh
    TEXT
    assert_true @board.insufficient_material?
  end

  def test_insufficient_material_kings_and_two_white_bishops
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒♚▒ ▒
      5 ▒ ▒ ♗♗▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒♔▒ ▒
        abcdefgh
    TEXT
    assert_false @board.insufficient_material?
  end

  def test_insufficient_material_kings_and_a_black_bishop
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒♚▒ ▒
      5 ▒ ▒ ♝ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒♔▒ ▒
        abcdefgh
    TEXT
    assert_true @board.insufficient_material?
  end

  def test_insufficient_material_kings_and_two_black_bishops
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒♚▒ ▒
      5 ▒ ▒ ♝♝▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒♔▒ ▒
        abcdefgh
    TEXT
    assert_false @board.insufficient_material?
  end

  def test_insufficient_material_kings_and_a_white_knight
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒♚▒ ▒
      5 ▒ ▒ ♘ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒♔▒ ▒
        abcdefgh
    TEXT
    assert_true @board.insufficient_material?
  end

  def test_insufficient_material_kings_and_two_white_knights
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒♚▒ ▒
      5 ▒ ▒ ♘♘▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒♔▒ ▒
        abcdefgh
    TEXT
    assert_false @board.insufficient_material?
  end

  def test_insufficient_material_kings_and_a_black_knight
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒♚▒ ▒
      5 ▒ ▒ ♞ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒♔▒ ▒
        abcdefgh
    TEXT
    assert_true @board.insufficient_material?
  end

  def test_insufficient_material_kings_and_a_black_knight_and_bishop
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒♚▒ ▒
      5 ▒ ▒ ♞♝▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒♔▒ ▒
        abcdefgh
    TEXT
    assert_false @board.insufficient_material?
  end

  def test_insufficient_material_kings_and_one_bishop_each
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒♚▒ ▒
      5 ▒ ▒ ♗♝▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ▒ ▒ ▒ ▒
      1 ▒ ▒♔▒ ▒
        abcdefgh
    TEXT
    assert_false @board.insufficient_material?
  end

  def test_white_pawn_promotion_to_queen
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
    @board.move(Coord.new(@board, 1, 5), Coord.new(@board, 0, 5))
    assert_current <<~TEXT
       ▒ ▒ ♕ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
    TEXT
  end

  def test_black_pawn_promotion_to_queen
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
    @board.move(Coord.new(@board, 6, 5), Coord.new(@board, 7, 5))
    assert_current <<~TEXT
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒♛▒
    TEXT
  end

  def test_incomplete_board_setup
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒♚▒ ▒
      5 ▒ ▒
      4  ▒
    TEXT
    assert_current <<~TEXT
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒♚▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
    TEXT
    assert_previous <<~TEXT
      ♜♞♝♛♚♝♞♜
      ♟♟♟♟♟♟♟♟
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
       ▒ ▒ ▒ ▒
      ▒ ▒ ▒ ▒
      ♙♙♙♙♙♙♙♙
      ♖♘♗♕♔♗♘♖
    TEXT
  end

  private def assert_current(text)
    assert_board text, @board
  end

  private def assert_previous(text)
    assert_board text, @board.previous
  end

  private def assert_board(text, board)
    assert_equal text.tr('▒', ' ').gsub(/ +$/, '').chomp,
                 board.current.join("\n").gsub(/ +$/, '')
  end

  private def move(notation, board = nil)
    board ||= @board
    board.move(*Coord.from_move(board, notation))
  end
end
