# coding: utf-8
# frozen_string_literal: true

require_relative 'coord'

# Knows the rules of chess, for instace which moves are legal.
class RuleBook
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
    other_color = (color == :white) ? :black : :white
    legal_moves(other_color, false) do |start, dest, take|
      return true if king_is_taken_by?(add_move_if_legal(start, dest, take))
    end
    false
  end

  def add_move_if_legal(start, dest, take)
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
    moves.any? { |m| %w[♚ ♔].include?(@board.get(Coord.from_move(m).last)) }
  end

  def insufficient_material?
    bishops_and_knights = 0
    (0...Board::SIZE).to_a.repeated_permutation(2).each do |row, col|
      piece = @board.get(Coord.new(row, col))
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
    Board::SIZE.times.each do |row|
      next if only_from && row != only_from[0]

      Board::SIZE.times.each do |col|
        next if only_from && col != only_from[1]

        current_coord = Coord.new(row, col)
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

    # King-side castle
    find_castle_move(current_coord, F..G, E..G, 7, &block)
    # Queen-side castle
    find_castle_move(current_coord, B..D, B..E, 0, &block)
  end

  private def legal_pawn_moves(current_coord, piece, &block)
    direction = (piece == '♟') ? 1 : -1
    forward = current_coord + [direction, 0]
    yield current_coord, forward, :cannot_take
    yield current_coord, forward.right, :must_take if current_coord.col < H
    yield current_coord, forward.left, :must_take if current_coord.col > A
    if current_coord.row == (piece == '♟' ? 1 : 6) &&
       @board.empty?(current_coord + [direction, 0])
      yield current_coord, current_coord + [2 * direction, 0], :cannot_take
    end
    if current_coord.row == (piece == '♟' ? 4 : 3)
      add_en_passant_if_legal(current_coord, 1, &block)
      add_en_passant_if_legal(current_coord, -1, &block)
    end
  end

  private def each_move_length(start)
    directions = case @board.get(start)
                 when '♜', '♖' then ROOK_DIRECTIONS
                 when '♝', '♗' then BISHOP_DIRECTIONS
                 when '♛', '♕' then ALL_DIRECTIONS
                 end
    piece_color = @board.color_at(start)
    other_color = (piece_color == :white) ? :black : :white
    directions.each do |y, x|
      (1...Board::SIZE).each do |scale|
        dest = start + [y * scale, x * scale]
        break if dest.outside_board?
        break if @board.color_at(dest) == piece_color

        yield dest
        break if @board.color_at(dest) == other_color
      end
    end
  end

  private def find_castle_move(current_coord, empty_columns,
                               unattacked_columns, rook_column)
    piece_color = @board.color_at(current_coord)
    royalty_row = (piece_color == :white) ? 7 : 0
    return unless current_coord.row == royalty_row

    rook = (piece_color == :white) ? '♖' : '♜'
    free_way =
      empty_columns.all? { |x| @board.empty?(Coord.new(current_coord.row, x)) }
    return unless free_way &&
                  @board.get(Coord.new(current_coord.row, rook_column)) == rook

    return if attacked?(current_coord, piece_color, unattacked_columns)
    return if @board.king_has_moved?(piece_color)

    if rook_column == 0
      return if @board.queen_side_rook_has_moved?(piece_color)
    elsif @board.king_side_rook_has_moved?(piece_color)
      return
    end

    king_destination = current_coord.col + ((rook_column == 0) ? -2 : 2)
    yield current_coord, Coord.new(current_coord.row, king_destination),
          :cannot_take
  end

  private def attacked?(current_coord, piece_color, unattacked_columns)
    other_color = (piece_color == :white) ? :black : :white
    legal_moves(other_color, false) do |_, dest, _|
      if dest.row == current_coord.row &&
         unattacked_columns.include?(dest.col)
        return true
      end
    end
    false
  end

  private def add_en_passant_if_legal(start, col_delta)
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
