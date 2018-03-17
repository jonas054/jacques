# coding: utf-8
# frozen_string_literal: true

require 'rainbow'
require 'forwardable'

# Represents the chess board and has some knowledge about the pieces.
class Board
  extend Forwardable

  # Remembers if kings or rooks have moved, which is important for evaluation
  # of whether it's legal to castle.
  class MovementRecord
    def initialize
      @record = {}
      @record[:white] = {}
      @record[:black] = {}
    end

    def king_has_moved?(color)
      @record[color][:king]
    end

    def king_side_rook_has_moved?(color)
      @record[color][:king_side_rook]
    end

    def queen_side_rook_has_moved?(color)
      @record[color][:queen_side_rook]
    end

    def check_movement(piece, start_col)
      case piece
      when '♔', '♚'
        color = piece == '♔' ? :white : :black
        @record[color][:king] = true
      when '♖', '♜'
        color = piece == '♖' ? :white : :black
        case start_col
        when 0 then @record[color][:queen_side_rook] = true
        when 7 then @record[color][:king_side_rook] = true
        end
      end
    end
  end

  SIZE = 8
  INITIAL_BOARD = ['♜♞♝♛♚♝♞♜',
                   '♟♟♟♟♟♟♟♟',
                   '        ',
                   '        ',
                   '        ',
                   '        ',
                   '♙♙♙♙♙♙♙♙',
                   '♖♘♗♕♔♗♘♖'].freeze
  EMPTY_SQUARE = ' '
  WHITE_PIECES = '♔♕♖♗♘♙'
  BLACK_PIECES = '♜♞♝♛♚♟'

  attr_reader :previous

  def_delegators :@movements,
                 :king_has_moved?,
                 :queen_side_rook_has_moved?,
                 :king_side_rook_has_moved?

  def initialize(original = nil)
    @squares = INITIAL_BOARD.join('-').split(/-/)
    if original
      (0...SIZE).each do |row|
        (0...SIZE).each do |col|
          @squares[row][col] = original.get(Coord.new(row, col))
        end
      end
    end
    @movements = MovementRecord.new
  end

  def setup(contents)
    @previous = Board.new(self)
    lines = contents.gsub(/^\d ?/, '').gsub(/\n  abcdefgh\n/, '')
                    .tr('▒', ' ').lines.map(&:chomp)
    lines += [''] * (8 - lines.size)
    @squares = lines.map { |row| row + ' ' * (8 - row.length) }
  end

  def notation
    @squares.join('/')
  end

  def current
    @squares
  end

  def empty?(coord)
    get(coord) == EMPTY_SQUARE
  end

  def only_kings_left?
    (0...SIZE).to_a.repeated_permutation(2).all? do |row, col|
      coord = Coord.new(row, col)
      empty?(coord) || %w[♔ ♚].include?(get(coord))
    end
  end

  def is_checked?(color)
    moves = []
    other_color = (color == :white) ? :black : :white
    RuleBook.legal_moves(other_color, self,
                         false) do |coord, new_coord, take|
      add_move_if_legal(moves, coord, new_coord, take)
    end
    king_is_taken_by?(moves.select { |move| move =~ /x/ })
  end

  def move_piece(chosen_move)
    start_coord = Coord.from_position(chosen_move[/^[a-h][1-8]/])
    new_coord = Coord.from_position(chosen_move[/[a-h][1-8]$/])
    move(start_coord, new_coord)
    [start_coord.row, start_coord.col, new_coord.row, new_coord.col]
  end

  def add_move_if_legal(result, coord, new_coord, take)
    taking = take == :must_take_en_passant || taking?(coord, new_coord)
    is_legal = case take
               when :cannot_take then empty?(new_coord)
               when :must_take then taking
               when :can_take then empty?(new_coord) || taking
               when :must_take_en_passant then true # conditions already checked
               end
    if is_legal
      result << (coord.position + (taking ? 'x' : '') + new_coord.position)
    end
  end

  def outside_board?(coord)
    !(0...SIZE).cover?(coord.row) || !(0...SIZE).cover?(coord.col)
  end

  def color_at(coord)
    return :none if empty?(coord)
    WHITE_PIECES.include?(get(coord)) ? :white : :black
  end

  def taking?(start_coord, new_coord)
    dest_color = color_at(new_coord)
    dest_color != :none && dest_color != color_at(start_coord)
  end

  def move(start_coord, new_coord)
    @previous = Board.new(self)
    piece = get(start_coord)

    case piece
    when '♙', '♟' then is_pawn = true
    when '♔', '♚' then is_king = true
    end

    @movements.check_movement(piece, start_coord.col)

    handle_en_passant(start_coord, new_coord) if is_pawn
    set(new_coord, piece)
    handle_pawn_promotion(piece, new_coord) if is_pawn
    set(start_coord, EMPTY_SQUARE)

    return unless (new_coord.col - start_coord.col).abs == 2 && is_king
    castle(start_coord.row, start_coord.col, new_coord.col)
  end

  private def handle_en_passant(start_coord, new_coord)
    return unless start_coord.col != new_coord.col && empty?(new_coord)
    @squares[start_coord.row][new_coord.col] = EMPTY_SQUARE
  end

  private def handle_pawn_promotion(piece, new_coord)
    return unless new_coord.row == 0 || new_coord.row == SIZE - 1
    set(new_coord, (piece == '♙') ? '♕' : '♛')
  end

  private def castle(start_row, start_col, new_col)
    rook_start_coord = Coord.new(start_row, new_col > start_col ? 7 : 0)
    rook = get(rook_start_coord)
    set(rook_start_coord, EMPTY_SQUARE)
    @squares[start_row][start_col + (new_col - start_col) / 2] = rook
  end

  private def set(coord, piece)
    @squares[coord.row][coord.col] = piece
  end

  def get(coord)
    @squares[coord.row][coord.col]
  end

  def draw(last_move = [])
    drawing = +''
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
      %w[♚ ♔].include?(get(Coord.from_position(move[-2..-1])))
    end
  end
end
