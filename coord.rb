# frozen_string_literal: true

# The coordinates on the chess board starting at (row=0, col=0) which is upper
# left corner.
class Coord
  attr_reader :row, :col

  def initialize(board, row, col)
    @board = board
    @row = row
    @col = col
  end

  def right
    Coord.new(@board, row, col + 1)
  end

  def left
    Coord.new(@board, row, col - 1)
  end

  def +(other)
    Coord.new(@board, row + other.first, col + other.last)
  end

  def outside_board?
    !(0...@board.size).cover?(row) || !(0...@board.size).cover?(col)
  end

  # Converts Coord(1, 2) into "b6".
  def position
    "#{'abcdefgh'[col]}#{@board.size - row}"
  end

  def to_s
    "#{position}(#{@board})"
  end

  # Converts "e2e4" into [Coord(7, 4), Coord(5, 4)].
  def self.from_move(board, move)
    pos = '[a-h][1-8]'
    [/^#{pos}/, /#{pos}$/].map { |regex| from_position(board, move[regex]) }
  end

  def self.from_position(board, pos)
    Coord.new(board, board.size - pos[1].to_i, pos[0].ord - 'a'.ord)
  end
end
