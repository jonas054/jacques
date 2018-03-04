# coding: utf-8

require 'rainbow'

class Board
  SIZE = 8
  INITIAL_BOARD = ['♜♞♝♛♚♝♞♜',
                   '♟♟♟♟♟♟♟♟',
                   '        ',
                   '        ',
                   '        ',
                   '        ',
                   '♙♙♙♙♙♙♙♙',
                   '♖♘♗♕♔♗♘♖'].freeze
  EMPTY_SQUARE = ' '.freeze
  WHITE_PIECES = '♔♕♖♗♘♙'.freeze
  BLACK_PIECES = '♜♞♝♛♚♟'.freeze

  attr_reader :previous

  def initialize(original = nil)
    @squares = INITIAL_BOARD.join('-').split(/-/)
    if original
      (0...SIZE).each do |row|
        (0...SIZE).each do |col|
          @squares[row][col] = original.get(row, col)
        end
      end
    end
  end

  def setup(contents)
    @previous = Board.new(self)
    lines = contents.gsub(/^\d ?/, '').gsub(/\n  abcdefgh\n/, '').
            gsub('▒', ' ').lines.map(&:chomp)
    lines += [''] * (8 - lines.size)
    @squares = lines.map { |row| row + ' ' * (8- row.length) }
  end

  def notation
    @squares.join('/')
  end

  def current
    @squares
  end

  def get(row, col)
    @squares[row][col]
  end

  def empty?(row, col)
    get(row, col) == EMPTY_SQUARE
  end

  def only_kings_left?
    SIZE.times do |row|
      SIZE.times do |col|
        next if empty?(row, col)
        return false unless %w[♔ ♚].include?(get(row, col))
      end
    end
    true
  end

  def outside_board?(row, col)
    row < 0 || row >= SIZE || col < 0 || col >= SIZE
  end

  def color_at(row, col)
    return :none if empty?(row, col)
    WHITE_PIECES.include?(get(row, col)) ? :white : :black
  end

  def taking?(row, col, new_row, new_col)
    WHITE_PIECES.include?(get(row, col)) &&
      BLACK_PIECES.include?(get(new_row, new_col)) ||
      BLACK_PIECES.include?(get(row, col)) &&
      WHITE_PIECES.include?(get(new_row, new_col))
  end

  def move(start_row, start_col, new_row, new_col)
    @previous = Board.new(self)
    piece = @squares[start_row][start_col]
    is_pawn = %w[♙ ♟].include?(piece)
    if is_pawn && start_col != new_col && empty?(new_row, new_col)
      # Taking en passant
      @squares[start_row][new_col] = EMPTY_SQUARE
    end
    @squares[new_row][new_col] =
      if is_pawn && (new_row == 0 || new_row == SIZE - 1)
        (piece == '♙') ? '♕' : '♛'
      else
        piece
      end
    @squares[start_row][start_col] = EMPTY_SQUARE
  end

  def draw(last_move = [])
    drawing = ''
    SIZE.times do |row|
      drawing << (SIZE - row).to_s
      SIZE.times do |col|
        square_color = col % 2 == row % 2 ? :ghostwhite : :gray
        if row == last_move[0] && col == last_move[1] ||
           row == last_move[2] && col == last_move[3]
          square_color = :yellow
        end
        drawing <<
          Rainbow(" #{@squares[row][col]} ").bg(square_color).fg(:black)
      end
      drawing << "\n"
    end
    drawing << "  a  b  c  d  e  f  g  h\n"
  end

  def king_is_taken_by?(taking_moves)
    taking_moves.any? do |move|
      row, col = get_coordinates(move[-2..-1])
      %w[♚ ♔].include?(get(row, col))
    end
  end

  def get_coordinates(pos)
    [SIZE - pos[1].to_i, pos[0].ord - 'a'.ord]
  end
end
