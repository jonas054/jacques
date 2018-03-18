# frozen_string_literal: true

# The coordinates on the chess board starting at (row=0, col=0) which is upper
# left corner.
class Coord < Struct.new(:row, :col) # rubocop:disable Style/StructInheritance
  def right
    Coord.new(row, col + 1)
  end

  def left
    Coord.new(row, col - 1)
  end

  def +(other)
    Coord.new(row + other.first, col + other.last)
  end

  def outside_board?
    !(0...Board::SIZE).cover?(row) || !(0...Board::SIZE).cover?(col)
  end

  # Converts Coord(1, 2) into "b6".
  def position
    "#{'abcdefgh'[col]}#{Board::SIZE - row}"
  end

  # Converts "e2e4" into [Coord(7, 4), Coord(5, 4)].
  def self.from_move(move)
    pos = '[a-h][1-8]'
    [/^#{pos}/, /#{pos}$/].map { |regex| from_position(move[regex]) }
  end

  def self.from_position(pos)
    Coord.new(Board::SIZE - pos[1].to_i, pos[0].ord - 'a'.ord)
  end
end
