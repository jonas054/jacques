# coding: utf-8
# frozen_string_literal: true

# Knows the rules of chess, for instace which moves are legal.
class RuleBook
  class << self
    def legal_moves(who_to_move, board, is_top_level_call = true,
                    only_from = nil, &block)
      Board::SIZE.times.each do |row|
        next if only_from && row != only_from[0]

        Board::SIZE.times.each do |col|
          next if only_from && col != only_from[1]

          piece_color = board.color_at(row, col)
          next unless piece_color == who_to_move

          legal_moves_from(board, row, col, is_top_level_call, &block)
        end
      end
    end

    private def legal_moves_from(board, row, col, is_top_level_call, &block)
      piece = board.get(row, col)
      current_coord = Coord.new(row, col)
      case piece
      when '♜', '♖', '♝', '♗', '♛', '♕'
        each_move_length(board, row, col) do |new_row, new_col|
          yield current_coord, Coord.new(new_row, new_col), :can_take
        end
      when '♞', '♘'
        KNIGHT_DIRECTIONS.each do |r, c|
          next if board.outside_board?(row + r, col + c)
          yield current_coord, Coord.new(row + r, col + c), :can_take
        end
      when '♚', '♔'
        ALL_DIRECTIONS.each do |y, x|
          next if board.outside_board?(row + y, col + x)
          yield current_coord, Coord.new(row + y, col + x), :can_take
        end
        if is_top_level_call && col == 4
          # King-side castle
          find_castle_move(board, row, col, 5..6, 4..6, 7, &block)
          # Queen-side castle
          find_castle_move(board, row, col, 1..3, 1..4, 0, &block)
        end
      when '♟', '♙'
        direction = (piece == '♟') ? 1 : -1
        yield current_coord, Coord.new(row + direction, col), :cannot_take
        if col < 7
          yield current_coord, Coord.new(row + direction, col + 1), :must_take
        end
        if col > 0
          yield current_coord, Coord.new(row + direction, col - 1), :must_take
        end
        if row == (piece == '♟' ? 1 : 6) && board.empty?(row + direction, col)
          yield current_coord, Coord.new(row + 2 * direction, col),
                :cannot_take
        end
        if row == (piece == '♟' ? 4 : 3)
          add_en_passant_if_legal(board, row, col, 1, &block)
          add_en_passant_if_legal(board, row, col, -1, &block)
        end
      end
    end

    private def each_move_length(board, row, col)
      directions = case board.get(row, col)
                   when '♜', '♖' then ROOK_DIRECTIONS
                   when '♝', '♗' then BISHOP_DIRECTIONS
                   when '♛', '♕' then ALL_DIRECTIONS
                   end
      piece_color = board.color_at(row, col)
      other_color = (piece_color == :white) ? :black : :white
      directions.each do |y, x|
        (1...Board::SIZE).each do |scale|
          new_row = row + y * scale
          new_col = col + x * scale
          break if board.outside_board?(new_row, new_col)
          break if board.color_at(new_row, new_col) == piece_color
          yield new_row, new_col
          break if board.color_at(new_row, new_col) == other_color
        end
      end
    end

    private def find_castle_move(board, row, col, empty_columns,
                                 unattacked_columns, rook_column)
      piece_color = board.color_at(row, col)
      royalty_row = (piece_color == :white) ? 7 : 0
      return unless row == royalty_row

      rook = (piece_color == :white) ? '♖' : '♜'
      return unless empty_columns.all? { |x| board.empty?(row, x) } &&
                    board.get(row, rook_column) == rook

      attacked = false
      other_color = (piece_color == :white) ? :black : :white
      legal_moves(other_color, board, false) do |_, new_coord, _|
        if new_coord.row == row && unattacked_columns.include?(new_coord.col)
          attacked = true
          break
        end
      end

      return if attacked
      return if board.king_has_moved?(piece_color)

      if rook_column == 0
        return if board.queen_side_rook_has_moved?(piece_color)
      elsif board.king_side_rook_has_moved?(piece_color)
        return
      end

      king_destination = (rook_column == 0) ? col - 2 : col + 2
      yield Coord.new(row, col), Coord.new(row, king_destination), :cannot_take
    end

    private def add_en_passant_if_legal(board, row, col, col_delta)
      new_col = col + col_delta
      return unless (0..7).cover?(new_col)

      pawn = board.get(row, col)
      opposite_pawn = (pawn == '♟') ? '♙' : '♟'
      return unless board.get(row, new_col) == opposite_pawn

      direction = (pawn == '♟') ? 1 : -1
      return unless board.previous.get(row + 2 * direction, new_col) ==
                    opposite_pawn

      yield Coord.new(row, col), Coord.new(row + direction, new_col),
            :must_take_en_passant
    end
  end
end
