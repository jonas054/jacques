# coding: utf-8
# frozen_string_literal: true

require 'rainbow'
require 'forwardable'
require_relative 'coord'
require_relative 'color'
require_relative 'rule_book'

# Represents the chess board and has some knowledge about the pieces.
class Board # rubocop:disable Metrics/ClassLength
  extend Forwardable
  include Color

  # Remembers if kings or rooks have moved, which is important for evaluation
  # of whether it's legal to castle.
  class MovementRecord
    include Color

    def initialize(size)
      @size = size
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
        @record[color_of(piece)][:king] = true
      when '♖', '♜'
        color = color_of(piece)
        case start_col
        when 0 then @record[color][:queen_side_rook] = true
        when @size - 1 then @record[color][:king_side_rook] = true
        end
      end
    end
  end

  INITIAL_BOARD = {
    4 => ['♜♛♚♜',
          '♟♟♟♟',
          '♙♙♙♙',
          '♖♕♔♖'],
    6 => ['♜♞♛♚♞♜',
          '♟♟♟♟♟♟',
          '      ',
          '      ',
          '♙♙♙♙♙♙',
          '♖♘♕♔♘♖'],
    8 => ['♜♞♝♛♚♝♞♜',
          '♟♟♟♟♟♟♟♟',
          '        ',
          '        ',
          '        ',
          '        ',
          '♙♙♙♙♙♙♙♙',
          '♖♘♗♕♔♗♘♖']
  }.freeze
  EMPTY_SQUARE = ' '
  WHITE_PIECES = '♔♕♖♗♘♙'

  attr_reader :previous, :size

  def_delegators :@movements,
                 :king_has_moved?,
                 :queen_side_rook_has_moved?,
                 :king_side_rook_has_moved?
  def_delegators :@rule_book, :insufficient_material?, :is_checked?
  def initialize(original: nil, show_taken_pieces: true, size: nil)
    @size = if size.nil?
              original ? original.size : 8
            else
              size
            end
    @show_taken_pieces = show_taken_pieces
    @taken = { white: [], black: [] }
    @squares = INITIAL_BOARD[@size].join('-').split(/-/)
    if original
      (0...@size).each do |row|
        (0...@size).each do |col|
          @squares[row][col] = original.get(Coord.new(self, row, col))
        end
      end
    end
    @movements = MovementRecord.new(@size)
    @moves_without_take = 0
    @rule_book = RuleBook.new(self)
    @drawing = Drawing.new(@size, @taken, @show_taken_pieces)
  end

  def setup(contents)
    setup_any do
      contents
        .gsub(/^\d ?/, '').gsub(/\n  abcdefgh\n/, '').tr('▒', ' ')
        .lines.map(&:chomp)
    end
  end

  # Forsyth-Edwards notation
  def setup_fen(fen)
    setup_any do
      fen[/\S+/]
        .tr('prnbqkPRNBQK', '♟♜♞♝♛♚♙♖♘♗♕♔').gsub(/\d/) { |x| ' ' * x.to_i }
        .split('/')
    end
  end

  private def setup_any
    @previous = Board.new(original: self, show_taken_pieces: @show_taken_pieces)
    lines = yield
    lines += [''] * (@size - lines.size)
    @squares = lines.map { |row| row + ' ' * (@size - row.length) }
  end

  def notation
    @squares.join('/')
  end

  def fen
    @squares
      .join('/')
      .tr('♟♜♞♝♛♚♙♖♘♗♕♔', 'prnbqkPRNBQK').gsub(/ +/) { |x| x.length.to_s }
  end

  def current
    @squares
  end

  def empty?(coord)
    get(coord) == EMPTY_SQUARE
  end

  def fifty_moves?
    @moves_without_take >= 100
  end

  def move_piece(chosen_move)
    start, dest = Coord.from_move(self, chosen_move)
    moving_piece = get(start)
    case moving_piece
    when '♙', '♟' then is_pawn = true
    end
    taken_piece = get(dest)
    taken_color = color_at(dest)
    @taken[taken_color] << taken_piece if taken_piece != EMPTY_SQUARE
    move(start, dest)
    @moves_without_take = if taken_piece == EMPTY_SQUARE && !is_pawn
                            @moves_without_take + 1
                          else
                            0
                          end
    [start.row, start.col, dest.row, dest.col]
  end

  def color_at(coord)
    empty?(coord) ? :none : color_of(get(coord))
  end

  def taking?(start, dest)
    ![:none, color_at(start)].include?(color_at(dest))
  end

  def move(start, dest)
    @previous = Board.new(original: self, show_taken_pieces: @show_taken_pieces)
    piece = get(start)

    case piece
    when '♙', '♟' then is_pawn = true
    when '♔', '♚' then is_king = true
    end

    @movements.check_movement(piece, start.col)

    handle_en_passant(start, dest) if is_pawn
    set(dest, piece)
    handle_pawn_promotion(piece == '♙', dest) if is_pawn
    set(start, EMPTY_SQUARE)

    return unless (dest.col - start.col).abs == 2 && is_king

    castle(start.row, start.col, dest.col)
  end

  private def handle_en_passant(start, dest)
    return unless start.col != dest.col && empty?(dest)

    taken_piece = @squares[start.row][dest.col]
    @taken[color_of(taken_piece)] << taken_piece

    @squares[start.row][dest.col] = EMPTY_SQUARE
  end

  private def handle_pawn_promotion(pawn_is_white, dest)
    set(dest, pawn_is_white ? '♕' : '♛') if [0, @size - 1].include?(dest.row)
  end

  private def castle(start_row, start_col, new_col)
    rook_start = Coord.new(self, start_row, new_col > start_col ? @size - 1 : 0)
    rook = get(rook_start)
    set(rook_start, EMPTY_SQUARE)
    @squares[start_row][start_col + (new_col - start_col) / 2] = rook
  end

  private def set(coord, piece)
    @squares[coord.row][coord.col] = piece
  end

  def get(coord)
    @squares[coord.row][coord.col]
  end

  def draw(last_move = [])
    @drawing.draw(@squares, last_move)
  end

  # Handles drawing of the board on the screen.
  class Drawing
    def initialize(size, taken, show_taken_pieces)
      @size = size
      @taken = taken
      @show_taken_pieces = show_taken_pieces
    end

    def draw(squares, last_move) # rubocop:disable Metrics/AbcSize
      drawing = +''
      @size.times do |row|
        drawing << (@size - row).to_s
        @size.times do |col|
          square_color = square_color(row, col, last_move)
          drawing <<
            Rainbow(" #{squares[row][col]} ").bg(square_color).fg(:black)
        end
        drawing << case row
                   when 0, @size - 1
                     # rubocop:disable Style/StringConcatenation
                     draw_taken_pieces(row == 0 ? :black : :white) + "\n"
                     # rubocop:enable Style/StringConcatenation
                   else
                     "\n"
                   end
      end
      drawing << '  ' << %w[a b c d e f g h][0, @size].join('  ') << "\n"
    end

    def square_color(row, col, last_move)
      if [row, col] == [last_move[0], last_move[1]] ||
         [row, col] == [last_move[2], last_move[3]]
        :yellow
      elsif col % 2 == row % 2
        :ghostwhite
      else
        :gray
      end
    end

    def draw_taken_pieces(color)
      if @show_taken_pieces && @taken[color].any?
        # rubocop:disable Style/StringConcatenation
        ' ' + Rainbow(@taken[color].join + ' ').bg(:blue).fg(:black)
        # rubocop:enable Style/StringConcatenation
      else
        ''
      end
    end
  end
end
