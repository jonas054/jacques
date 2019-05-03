# coding: utf-8
# frozen_string_literal: true

require 'rainbow'
require 'forwardable'
require_relative 'coord'
require_relative 'rule_book'

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

  def initialize(original: nil, show_taken_pieces: true)
    @show_taken_pieces = show_taken_pieces
    @taken = { white: [], black: [] }
    @squares = INITIAL_BOARD.join('-').split(/-/)
    if original
      (0...SIZE).each do |row|
        (0...SIZE).each do |col|
          @squares[row][col] = original.get(Coord.new(row, col))
        end
      end
    end
    @movements = MovementRecord.new
    @moves_without_take = 0
    @rule_book = RuleBook.new(self)
  end

  def setup(contents)
    @previous = Board.new(original: self, show_taken_pieces: @show_taken_pieces)
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

  def insufficient_material?
    @rule_book.insufficient_material?
  end

  def fifty_moves?
    @moves_without_take >= 100
  end

  def is_checked?(color)
    other_color = (color == :white) ? :black : :white
    @rule_book.legal_moves(other_color, false) do |start, dest, take|
      return true if @rule_book.king_is_taken_by?(add_move_if_legal(start, dest,
                                                                    take))
    end
    false
  end

  def move_piece(chosen_move)
    start, dest = Coord.from_move(chosen_move)
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

  def add_move_if_legal(start, dest, take)
    taking = take == :must_take_en_passant || taking?(start, dest)
    is_legal = case take
               when :cannot_take then empty?(dest)
               when :must_take then taking
               when :can_take then empty?(dest) || taking
               when :must_take_en_passant then true # conditions already checked
               end
    return [] unless is_legal

    [start.position + (taking ? 'x' : '') + dest.position]
  end

  def color_at(coord)
    return :none if empty?(coord)

    WHITE_PIECES.include?(get(coord)) ? :white : :black
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
    taken_color = WHITE_PIECES.include?(taken_piece) ? :white : :black
    @taken[taken_color] << taken_piece

    @squares[start.row][dest.col] = EMPTY_SQUARE
  end

  private def handle_pawn_promotion(pawn_is_white, dest)
    dest_col = dest.col
    other_king = pawn_is_white ? '♚' : '♔'
    one_row_away = pawn_is_white ? 1 : 6
    two_rows_away = pawn_is_white ? 2 : 5
    new_piece = if @squares[two_rows_away][dest_col + 1] == other_king ||
                   @squares[two_rows_away][dest_col - 1] == other_king ||
                   @squares[one_row_away][dest_col + 2] == other_king ||
                   @squares[one_row_away][dest_col - 2] == other_king
                  pawn_is_white ? '♘' : '♞'
                else
                  pawn_is_white ? '♕' : '♛'
                end
    set(dest, new_piece) if [0, SIZE - 1].include?(dest.row)
  end

  private def castle(start_row, start_col, new_col)
    rook_start = Coord.new(start_row, new_col > start_col ? 7 : 0)
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
    drawing = +''
    SIZE.times do |row|
      drawing << (SIZE - row).to_s
      SIZE.times do |col|
        square_color = if [row, col] == [last_move[0], last_move[1]] ||
                          [row, col] == [last_move[2], last_move[3]]
                         :yellow
                       elsif col % 2 == row % 2
                         :ghostwhite
                       else
                         :gray
                       end
        drawing <<
          Rainbow(" #{@squares[row][col]} ").bg(square_color).fg(:black)
      end
      drawing << case row
                 when 0, 7
                   draw_taken_pieces(row == 0 ? :black : :white) + "\n"
                 else
                   "\n"
                 end
    end
    drawing << "  a  b  c  d  e  f  g  h\n"
  end

  def draw_taken_pieces(color)
    if @show_taken_pieces && @taken[color].any?
      ' ' + Rainbow(@taken[color].join('') + ' ').bg(:blue).fg(:black)
    else
      ''
    end
  end
end
