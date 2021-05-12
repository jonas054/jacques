# coding: utf-8

# frozen_string_literal: true

require 'test/unit'
require_relative 'brain'

# Tests the methods in the Brain class.
class TestBrain < Test::Unit::TestCase
  def setup
    @board = Board.new
    @brain = Brain.new
    @brain.board = @board
  end

  def test_prefer_mate_over_other_check
    srand 2
    @board.setup(<<~TEXT)
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ♛ ▒
      2  ♚ ▒ ▒ ♜
      1 ▒ ▒♔▒ ▒
        abcdefgh
    TEXT
    @board.move_piece(@brain.choose_move(:black))
    assert_board <<~TEXT
      8  ▒ ▒ ▒ ▒
      7 ▒ ▒ ▒ ▒
      6  ▒ ▒ ▒ ▒
      5 ▒ ▒ ▒ ▒
      4  ▒ ▒ ▒ ▒
      3 ▒ ▒ ▒ ▒
      2  ♚ ♛ ▒ ♜
      1 ▒ ▒♔▒ ▒
        abcdefgh
    TEXT
    assert_nil @brain.choose_move(:white) # No legal moves available
  end

  private def assert_board(text)
    # rubocop:disable Style/StringConcatenation
    assert_equal clean(text), @board.current.join("\n").gsub(/ +$/, '') + "\n"
    # rubocop:enable Style/StringConcatenation
  end

  private def clean(board_setup)
    board_setup.tr('▒', ' ').gsub(/^\d+ /, '').gsub(/ +$/, '')
               .sub("  abcdefgh\n", '')
  end
end
