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
end
