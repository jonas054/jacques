# coding: utf-8
# frozen_string_literal: true

# The part that figures out which moves to make.
class Brain
  attr_writer :board

  SCORE = { '♛' => 9, '♜' => 5, '♞' => 3, '♝' => 3, '♟' => 1,
            '♕' => 9, '♖' => 5, '♘' => 3, '♗' => 3, '♙' => 1 }.freeze
  def choose_move(who_to_move)
    legal_moves = all_legal_moves_that_dont_put_me_in_check(who_to_move)

    return nil if legal_moves.empty?

    best_moves = checking_moves(legal_moves)
    best_moves = castling_moves(legal_moves) if best_moves.empty?
    best_moves = taking_moves(legal_moves) if best_moves.empty?
    best_moves = legal_moves if best_moves.empty?
    best_moves = remove_dangerous_moves(best_moves, who_to_move)
    best_moves = legal_moves if best_moves.empty?
    best_moves.sample
  end

  private def checking_moves(moves)
    moves.select { |move| is_checking_move?(move) }
  end

  private def castling_moves(moves)
    moves.select { |m| is_castling_move?(m) }
  end

  private def taking_moves(moves)
    taking = moves.select { |move| move =~ /x/ }
    sorted = taking.sort_by { |move| SCORE[taken_piece(move)] }
    return [] if sorted.empty?
    most_valuable_piece = taken_piece(sorted.last)
    sorted.select { |move| taken_piece(move) == most_valuable_piece }
  end

  private def taken_piece(move)
    coord = Coord.from_move(move)
    piece = @board.get(coord.last)
    return piece if piece != Board::EMPTY_SQUARE
    # En passant
    (@board.color_at(coord.first) == :white) ? '♟' : '♙'
  end

  private def all_legal_moves_that_dont_put_me_in_check(who_to_move)
    moves = []
    RuleBook.legal_moves(who_to_move, @board) do |coord, dest, take|
      new_board = Board.new(@board)
      color_of_moving_piece = new_board.color_at(coord)
      new_board.move(coord, dest)
      next if new_board.is_checked?(color_of_moving_piece)

      moves += @board.add_move_if_legal(coord, dest, take)
    end
    moves
  end

  # Return the given best moves except the ones that move to a square attacked
  # by the other player.
  private def remove_dangerous_moves(best_moves, who_to_move)
    other_color = (who_to_move == :white) ? :black : :white
    RuleBook.legal_moves(other_color, @board) do |_, dest, take|
      next if take == :cannot_take
      dangerous = best_moves.select { |m| m.end_with?(dest.position) }
      best_moves -= dangerous
    end
    best_moves
  end

  private def is_castling_move?(move)
    start, dest = Coord.from_move(move)
    %w[♚ ♔].include?(@board.get(start)) &&
      # rubocop:disable Layout/MultilineOperationIndentation
      (dest.col - start.col).abs == 2
    # rubocop:enable Layout/MultilineOperationIndentation
  end

  private def is_checking_move?(move)
    start, dest = Coord.from_move(move)
    new_board = Board.new(@board)
    color_of_moving_piece = new_board.color_at(start)
    other_color = (color_of_moving_piece == :white) ? :black : :white
    new_board.move(start, dest)
    new_board.is_checked?(other_color)
  end
end
