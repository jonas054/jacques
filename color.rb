# coding: utf-8
# frozen_string_literal: true

# Logic around pieces being black or white.
module Color
  def color_of(piece)
    Board::WHITE_PIECES.include?(piece) ? :white : :black
  end

  def other_color(color)
    (color == :white) ? :black : :white
  end
end
