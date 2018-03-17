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

  # Converts 1, 2 into "b6".
  def position
    "#{'abcdefgh'[col]}#{Board::SIZE - row}"
  end

  def self.from_position(pos)
    Coord.new(Board::SIZE - pos[1].to_i, pos[0].ord - 'a'.ord)
  end
end
