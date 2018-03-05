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
    @movements = {}
    @movements[:white] = {}
    @movements[:black] = {}
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

  def king_has_moved?(color)
    @movements[color][:king]
  end

  def king_side_rook_has_moved?(color)
    @movements[color][:king_side_rook]
  end

  def queen_side_rook_has_moved?(color)
    @movements[color][:queen_side_rook]
  end

  def move(start_row, start_col, new_row, new_col)
    @previous = Board.new(self)
    piece = @squares[start_row][start_col]
    color = color_at(start_row, start_col)

    case piece
    when '♙', '♟'
      is_pawn = true
    when '♔', '♚'
      is_king = true
      @movements[color][:king] = true
    when '♖', '♜'
      case start_col
      when 0 then @movements[color][:queen_side_rook] = true
      when 7 then @movements[color][:king_side_rook] = true
      end
    end

    if is_pawn && start_col != new_col && empty?(new_row, new_col)
      # Taking en passant
      @squares[start_row][new_col] = EMPTY_SQUARE
    end
    @squares[new_row][new_col] =
      if is_pawn && (new_row == 0 || new_row == SIZE - 1)
        # Pawn promotion
        (piece == '♙') ? '♕' : '♛'
      else
        piece
      end
    @squares[start_row][start_col] = EMPTY_SQUARE
    # Castling
    if (new_col - start_col).abs == 2 && is_king
      rook_start_col = new_col > start_col ? 7 : 0
      rook = @squares[start_row][rook_start_col]
      @squares[start_row][rook_start_col] = EMPTY_SQUARE
      @squares[start_row][start_col + (new_col - start_col) / 2] = rook
    end
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
