# coding: utf-8
# frozen_string_literal: true

# The AI part that figures out which moves to make.
class Brain
  def initialize(rules, board)
    @rules = rules
    @board = board
  end

  def choose_move(turn, who_to_move)
    my_moves = []
    @rules.legal_moves(who_to_move, @board,
                       :is_top_level_call) do |board, coord, new_coord, take|
      board.add_move_if_legal(my_moves, coord, new_coord, take)
    end

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

    chosen_moves = if best_moves.any?
                     best_moves
                   else
                     my_moves
                   end
    other_color = (who_to_move == :white) ? :black : :white
    @rules.legal_moves(other_color, @board,
                       :is_top_level_call) do |_, _, new_coord, take|
      next if take == :cannot_take
      dangerous = chosen_moves.select do |m|
        m.end_with?(@board.position(new_coord.row, new_coord.col))
      end
      chosen_moves -= dangerous if dangerous.size < chosen_moves.size
    end
    chosen_move = chosen_moves.sample
    puts "#{turn}.#{'..' if who_to_move == :black}#{chosen_move}"
    chosen_move
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
