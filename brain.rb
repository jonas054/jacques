# coding: utf-8
# frozen_string_literal: true

# The AI part that figures out which moves to make.
class Brain
  attr_writer :board

  def choose_move(who_to_move)
    my_moves = all_legal_moves_that_dont_put_me_in_check(who_to_move)

    return nil if my_moves.empty?

    checking_moves = my_moves.select { |move| is_checking_move?(move) }
    best_moves = if checking_moves.any?
                   checking_moves
                 else
                   castling_moves = my_moves.select { |m| is_castling_move?(m) }
                   if castling_moves.any?
                     castling_moves
                   else
                     my_moves.select { |move| move =~ /x/ }
                   end
                 end

    chosen_moves = best_moves.any? ? best_moves : my_moves
    other_color = (who_to_move == :white) ? :black : :white
    RuleBook.legal_moves(other_color, @board) do |_, new_coord, take|
      next if take == :cannot_take
      dangerous = chosen_moves.select { |m| m.end_with?(new_coord.position) }
      chosen_moves -= dangerous if dangerous.size < chosen_moves.size
    end
    chosen_moves.sample
  end

  private def all_legal_moves_that_dont_put_me_in_check(who_to_move)
    my_moves = []
    RuleBook.legal_moves(who_to_move, @board) do |coord, new_coord, take|
      new_board = Board.new(@board)
      color_of_moving_piece = new_board.color_at(coord.row, coord.col)
      new_board.move(coord.row, coord.col, new_coord.row, new_coord.col)
      next if new_board.is_checked?(color_of_moving_piece)

      @board.add_move_if_legal(my_moves, coord, new_coord, take)
    end
    my_moves
  end

  private def is_castling_move?(move)
    row, col = @board.get_coordinates(move[/^[a-h][1-8]/])
    _, new_col = @board.get_coordinates(move[/[a-h][1-8]$/])
    %w[♚ ♔].include?(@board.get(row, col)) && (new_col - col).abs == 2
  end

  private def is_checking_move?(move)
    row, col = @board.get_coordinates(move[/^[a-h][1-8]/])
    new_row, new_col = @board.get_coordinates(move[/[a-h][1-8]$/])
    new_board = Board.new(@board)
    color_of_moving_piece = new_board.color_at(row, col)
    other_color = (color_of_moving_piece == :white) ? :black : :white
    new_board.move(row, col, new_row, new_col)
    new_board.is_checked?(other_color)
  end
end
