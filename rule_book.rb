# coding: utf-8
# frozen_string_literal: true

# Knows the rules of chess, for instace which moves are legal.
class RuleBook
  def legal_moves(who_to_move, board, is_top_level_call, only_from = nil,
                  &block)
    Board::SIZE.times.each do |row|
      next if only_from && row != only_from[0]

      Board::SIZE.times.each do |col|
        next if only_from && col != only_from[1]

        piece_color = board.color_at(row, col)
        next unless piece_color == who_to_move

        piece = board.get(row, col)
        other_color = (piece_color == :white) ? :black : :white
        current_coord = Coord.new(row, col)
        case piece
        when '♜', '♖'
          ROOK_DIRECTIONS.each do |y, x|
            (1...Board::SIZE).each do |scale|
              new_row = row + y * scale
              new_col = col + x * scale
              break if board.outside_board?(new_row, new_col)
              break if board.color_at(new_row, new_col) == piece_color
              yield board, current_coord, Coord.new(new_row, new_col),
                    :can_take
              break if board.color_at(new_row, new_col) == other_color
            end
          end
        when '♞', '♘'
          KNIGHT_DIRECTIONS.each do |r, c|
            unless board.outside_board?(row + r, col + c)
              yield board, current_coord, Coord.new(row + r, col + c),
                    :can_take
            end
          end
        when '♝', '♗'
          BISHOP_DIRECTIONS.each do |y, x|
            (1...Board::SIZE).each do |scale|
              new_row = row + y * scale
              new_col = col + x * scale
              break if board.outside_board?(new_row, new_col)
              break if board.color_at(new_row, new_col) == piece_color
              yield board, current_coord, Coord.new(new_row, new_col),
                    :can_take
              break if board.color_at(new_row, new_col) == other_color
            end
          end
        when '♚', '♔'
          ALL_DIRECTIONS.each do |y, x|
            unless board.outside_board?(row + y, col + x)
              yield board, current_coord, Coord.new(row + y, col + x),
                    :can_take
            end
          end
          if is_top_level_call && col == 4
            # King-side castle
            find_castle_move(board, row, col, 5..6, 4..6, 7, &block)
            # Queen-side castle
            find_castle_move(board, row, col, 1..3, 1..4, 0, &block)
          end
        when '♛', '♕'
          ALL_DIRECTIONS.each do |y, x|
            (1...Board::SIZE).each do |scale|
              new_row = row + y * scale
              new_col = col + x * scale
              break if board.outside_board?(new_row, new_col)
              break if board.color_at(new_row, new_col) == piece_color
              yield board, current_coord, Coord.new(new_row, new_col),
                    :can_take
              break if board.color_at(new_row, new_col) == other_color
            end
          end
        when '♟', '♙'
          direction = (piece == '♟') ? 1 : -1
          yield board, current_coord, Coord.new(row + direction, col),
                :cannot_take
          if col < 7
            yield board, current_coord,
                  Coord.new(row + direction, col + 1), :must_take
          end
          if col > 0
            yield board, current_coord,
                  Coord.new(row + direction, col - 1), :must_take
          end
          if row == (piece == '♟' ? 1 : 6) &&
             board.empty?(row + direction, col)
            yield board, current_coord,
                  Coord.new(row + 2 * direction, col), :cannot_take
          end
          if row == (piece_color == :black ? 4 : 3)
            add_en_passant_if_legal(board, row, col, 1, &block)
            add_en_passant_if_legal(board, row, col, -1, &block)
          end
        end
      end
    end
  end

  private def find_castle_move(board, row, col, empty_columns,
                               unattacked_columns, rook_column)
    piece_color = board.color_at(row, col)
    royalty_row = (piece_color == :white) ? 7 : 0
    return unless row == royalty_row

    rook = (piece_color == :white) ? '♖' : '♜'
    if empty_columns.all? { |x| board.empty?(row, x) } &&
       board.get(row, rook_column) == rook
      attacked = false
      other_color = (piece_color == :white) ? :black : :white
      royalty_row = (piece_color == :white) ? 7 : 0
      legal_moves(other_color, board, false) do |_, _, new_coord, _|
        if new_coord.row == royalty_row &&
           unattacked_columns.include?(new_coord.col)
          attacked = true
          break
        end
      end

      rook_has_moved = if rook_column == 0
                         board.queen_side_rook_has_moved?(piece_color)
                       else
                         board.king_side_rook_has_moved?(piece_color)
                       end

      unless attacked || board.king_has_moved?(piece_color) || rook_has_moved
        king_destination = (rook_column == 0) ? col - 2 : col + 2
        yield board, Coord.new(row, col), Coord.new(row, king_destination),
              :cannot_take
      end
    end
  end

  private def add_en_passant_if_legal(board, row, col, col_delta)
    piece = board.get(row, col)
    opposite_piece = (piece == '♟') ? '♙' : '♟'
    direction = (piece == '♟') ? 1 : -1
    return unless (0..7).cover?(col + col_delta)

    if board.get(row, col + col_delta) == opposite_piece &&
       board.previous.get(row + 2 * direction, col + col_delta) ==
       opposite_piece
      yield board, Coord.new(row, col),
            Coord.new(row + direction, col + col_delta), :must_take_en_passant
    end
  end
end
