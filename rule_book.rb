# coding: utf-8
# frozen_string_literal: true

require_relative 'coord'
require_relative 'color'

# Knows the rules of chess, for instace which moves are legal.
class RuleBook # rubocop:disable Metrics/ClassLength
  include Color

  A, B, C, D, E, F, G, H = (0..7).to_a

  ALL_DIRECTIONS =
    [-1, 0, 1].repeated_permutation(2).reject { |y, x| x == 0 && y == 0 }
  KNIGHT_DIRECTIONS = [1, 2, -1, -2].permutation(2).select do |x, y|
    x.abs + y.abs == 3
  end
  BISHOP_DIRECTIONS = [-1, 1].repeated_permutation(2)
  ROOK_DIRECTIONS = [-1, 0, 1].repeated_permutation(2).reject do |x, y|
    x.abs == y.abs
  end

  def initialize(board)
    @board = board
  end

  def is_checked?(color)
    legal_moves(other_color(color), false) do |start, dest, take|
      return true if king_is_taken_by?(add_move_if_legal(start, dest, take))
    end
    false
  end

  def add_move_if_legal(start, dest, take)
    raise if dest.col >= @board.size

    taking = take == :must_take_en_passant || @board.taking?(start, dest)
    is_legal = case take
               when :cannot_take then @board.empty?(dest)
               when :must_take then taking
               when :can_take then @board.empty?(dest) || taking
               when :must_take_en_passant then true # conditions already checked
               end
    return [] unless is_legal

    [start.position + (taking ? 'x' : '') + dest.position]
  end

  def king_is_taken_by?(moves)
    moves.any? do |m|
      %w[♚ ♔].include?(@board.get(Coord.from_move(@board, m).last))
    end
  end

  def insufficient_material?
    bishops_and_knights = 0
    (0...@board.size).to_a.repeated_permutation(2).each do |row, col|
      piece = @board.get(Coord.new(@board, row, col))
      case piece
      when '♗', '♘', '♝', '♞' then bishops_and_knights += 1
      when '♔', '♚', Board::EMPTY_SQUARE then nil
      else return false # queen, rook, or pawn means sufficient to checkmate
      end
    end
    bishops_and_knights < 2
  end

  def legal_moves(who_to_move, is_top_level_call = true, only_from = nil,
                  &block)
    @board.size.times.each do |row|
      next if only_from && row != only_from[0]

      @board.size.times.each do |col|
        next if only_from && col != only_from[1]

        current_coord = Coord.new(@board, row, col)
        piece_color = @board.color_at(current_coord)
        next unless piece_color == who_to_move

        legal_moves_from(current_coord, is_top_level_call, &block)
      end
    end
  end
  private def legal_moves_from(current_coord, is_top_level_call, &block)
    piece = @board.get(current_coord)
    case piece
    when '♜', '♖', '♝', '♗', '♛', '♕'
      each_move_length(current_coord) do |dest|
        yield current_coord, dest, :can_take
      end
    when '♞', '♘'
      legal_knight_moves(current_coord, &block)
    when '♚', '♔'
      legal_king_moves(current_coord, is_top_level_call, &block)
    when '♟', '♙'
      legal_pawn_moves(current_coord, piece, &block)
    end
  end

  private def legal_knight_moves(current_coord)
    KNIGHT_DIRECTIONS.each do |r, c|
      dest = current_coord + [r, c]
      yield current_coord, dest, :can_take unless dest.outside_board?
    end
  end

  private def legal_king_moves(current_coord, is_top_level_call, &block)
    ALL_DIRECTIONS.each do |y, x|
      next if (current_coord + [y, x]).outside_board?

      yield current_coord, current_coord + [y, x], :can_take
    end
    return unless is_top_level_call && current_coord.col == E

    # TODO: Support catling for smaller boards
    if @board.size == 8
      # King-side castle
      find_castle_move(current_coord, F..G, E..G, 7, &block)
      # Queen-side castle
      find_castle_move(current_coord, B..D, B..E, 0, &block)
    end
  end

  # rubocop:disable Metrics/AbcSize
  private def legal_pawn_moves(current_coord, piece, &block)
    black_to_move = piece == '♟'
    direction = black_to_move ? 1 : -1
    forward = current_coord + [direction, 0]
    yield current_coord, forward, :cannot_take

    if current_coord.col < @board.size - 1
      yield current_coord, forward.right, :must_take
    end
    yield current_coord, forward.left, :must_take if current_coord.col > A
    if current_coord.row == (black_to_move ? 1 : @board.size - 2) &&
       @board.empty?(current_coord + [direction, 0])
      yield current_coord, current_coord + [2 * direction, 0], :cannot_take
    end
    return unless current_coord.row == (black_to_move ? 4 : 3)

    [1, -1].each do |col_delta|
      add_en_passant_if_legal(current_coord, col_delta, &block)
    end
  end
  # rubocop:enable Metrics/AbcSize

  private def each_move_length(start)
    directions = case @board.get(start)
                 when '♜', '♖' then ROOK_DIRECTIONS
                 when '♝', '♗' then BISHOP_DIRECTIONS
                 when '♛', '♕' then ALL_DIRECTIONS
                 end
    piece_color = @board.color_at(start)
    other_color = other_color(piece_color)
    directions.each do |y, x|
      (1...@board.size).each do |scale|
        dest = start + [y * scale, x * scale]
        break if dest.outside_board?
        break if @board.color_at(dest) == piece_color

        yield dest
        break if @board.color_at(dest) == other_color
      end
    end
  end

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  private def find_castle_move(current_coord, empty_columns,
                               unattacked_columns, rook_column)
    piece_color = @board.color_at(current_coord)
    royalty_row = (piece_color == :white) ? 7 : 0
    return unless current_coord.row == royalty_row

    rook = (piece_color == :white) ? '♖' : '♜'
    free_way = empty_columns.all? do |x|
      @board.empty?(Coord.new(@board, current_coord.row, x))
    end
    rook_in_its_original_position =
      @board.get(Coord.new(@board, current_coord.row, rook_column)) == rook
    return unless free_way && rook_in_its_original_position

    return if attacked?(current_coord, piece_color, unattacked_columns)
    return if @board.king_has_moved?(piece_color)

    if rook_column == 0
      return if @board.queen_side_rook_has_moved?(piece_color)
    elsif @board.king_side_rook_has_moved?(piece_color)
      return
    end

    king_destination = current_coord.col + ((rook_column == 0) ? -2 : 2)
    yield current_coord, Coord.new(@board, current_coord.row, king_destination),
          :cannot_take
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity

  private def attacked?(current_coord, piece_color, unattacked_columns)
    legal_moves(other_color(piece_color), false) do |_, dest, _|
      if dest.row == current_coord.row &&
         unattacked_columns.include?(dest.col)
        return true
      end
    end
    false
  end
  private def add_en_passant_if_legal(start, col_delta)
    return if @board.size < 8 # En passant not possible on smaller boards.

    return unless (A..H).cover?(start.col + col_delta)

    pawn = @board.get(start)
    opposite_pawn = (pawn == '♟') ? '♙' : '♟'
    return if @board.get(start + [0, col_delta]) != opposite_pawn

    direction = (pawn == '♟') ? 1 : -1
    return if @board.previous.get(start + [2 * direction, col_delta]) !=
              opposite_pawn

    yield start, start + [direction, col_delta],
          :must_take_en_passant
  end
end
