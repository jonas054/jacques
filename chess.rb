# coding: utf-8
require 'rainbow'
require_relative 'board'

# TODO:
# - Draw due to repeated moves
# - Smarter selection of moves
# - Human opponent
ALL_DIRECTIONS =
  [-1, 0, 1].repeated_permutation(2).reject { |y, x| x == 0 && y == 0 }
ROOK_DIRECTIONS = [-1, 0, 1].repeated_permutation(2).reject do |x, y|
  x.abs == y.abs
end

class Chess
  def initialize
    @board = Board.new
  end

  def main
    puts run
  end

  def run
    puts @board.draw
    i = -1
    loop do
      i += 1
      color = i.even? ? :white : :black
      move = make_move(i / 2 + 1, color)
      if move.nil?
        return is_checked?(@board, color) ? "Checkmate" : "Stalemate"
      end

      puts draw(move)
      return "Draw" if @board.only_kings_left?
    end
  end

  def draw(args)
    @board.draw(args)
  end

  def make_move(turn, who_to_move)
    my_moves = legal_moves(who_to_move, @board)
    return nil if my_moves.empty?

    checking_moves = my_moves.select { |move| is_checking_move?(move) }
    best_moves = if checking_moves.any?
                     checking_moves
                   else
                     my_moves.select { |move| move =~ /x/ }
                   end

    chosen_move = (best_moves.any? ? best_moves : my_moves).sample
    puts "#{turn}.#{'..' if who_to_move == :black}#{chosen_move}"
    start_row, start_col = @board.get_coordinates(chosen_move[0, 2])
    new_row, new_col = @board.get_coordinates(chosen_move[-2..-1])
    @board.move(start_row, start_col, new_row, new_col)
    [start_row, start_col, new_row, new_col]
  end

  def is_checking_move?(move)
    row, col = @board.get_coordinates(move[0, 2])
    new_row, new_col = @board.get_coordinates(move[-2..-1])
    new_board = Board.new(@board)
    color_of_moving_piece = new_board.color_at(row, col)
    other_color = (color_of_moving_piece == :white) ? :black : :white
    new_board.move(row, col, new_row, new_col)
    is_checked?(new_board, other_color)
  end

  def legal_moves(who_to_move, board)
    result = []
    Board::SIZE.times.each do |row|
      Board::SIZE.times.each do |col|
        piece = board.get(row, col)
        piece_color = board.color_at(row, col)
        next unless piece_color == who_to_move

        other_color = (piece_color == :white) ? :black : :white
        case piece
        when '♜', '♖'
          ROOK_DIRECTIONS.each do |y, x|
            (1...Board::SIZE).each do |scale|
              new_row = row + y * scale
              new_col = col + x * scale
              break if board.outside_board?(new_row, new_col)
              break if board.color_at?(piece_color, new_row, new_col)
              add_move_if_legal(result, board, row, col, new_row, new_col)
              break if board.color_at?(other_color, new_row, new_col)
            end
          end
        when '♞', '♘'
          [1, 2, -1, -2].permutation(2).select do |x, y|
            x.abs + y.abs == 3
          end.each do |r, c|
            add_move_if_legal(result, board, row, col, row + r, col + c)
          end
        when '♝', '♗'
          [-1, 1].repeated_permutation(2).each do |y, x|
            (1...Board::SIZE).each do |scale|
              new_row = row + y * scale
              new_col = col + x * scale
              break if board.outside_board?(new_row, new_col)
              break if board.color_at?(piece_color, new_row, new_col)
              add_move_if_legal(result, board, row, col, new_row, new_col)
              break if board.color_at?(other_color, new_row, new_col)
            end
          end
        when '♚', '♔'
          ALL_DIRECTIONS.each do |y, x|
            add_move_if_legal(result, board, row, col, row + y, col + x)
          end
        when '♛', '♕'
          ALL_DIRECTIONS.each do |y, x|
            (1...Board::SIZE).each do |scale|
              new_row = row + y * scale
              new_col = col + x * scale
              break if board.outside_board?(new_row, new_col)
              break if board.color_at?(piece_color, new_row, new_col)
              add_move_if_legal(result, board, row, col, new_row, new_col)
              break if board.color_at?(other_color, new_row, new_col)
            end
          end
        when '♟', '♙'
          direction = piece == '♟' ? 1 : -1
          add_move_if_legal(result, board, row, col, row + direction, col,
                            :cannot_take)
          add_move_if_legal(result, board, row, col, row + direction, col + 1,
                            :must_take)
          add_move_if_legal(result, board, row, col, row + direction, col - 1,
                            :must_take)
          if row == (piece == '♟' ? 1 : 6) &&
             board.empty?(row + direction, col)
            add_move_if_legal(result, board, row, col, row + 2 * direction, col,
                              :cannot_take)
          end
        end
      end
    end
    result
  end

  def add_move_if_legal(result, board, row, col, new_row, new_col,
                        take = :can_take)
    return if board.outside_board?(new_row, new_col)
    taking = board.taking?(row, col, new_row, new_col)
    unless @just_looking
      new_board = Board.new(board)
      color_of_moving_piece = new_board.color_at(row, col)
      new_board.move(row, col, new_row, new_col)

      # puts new_board.draw
      @just_looking = true
      is_checked = is_checked?(new_board, color_of_moving_piece)
      @just_looking = false
      return if is_checked
    end

    is_legal = case take
               when :cannot_take
                 board.empty?(new_row, new_col)
               when :must_take
                 taking
               when :can_take
                 board.empty?(new_row, new_col) || taking
               end
    if is_legal
      result << (position(row, col) + (taking ? 'x' : '') +
                 position(new_row, new_col))
    end
  end

  # Converts 1, 2 into "b6".
  def position(row, col)
    "#{'abcdefgh'[col]}#{Board::SIZE - row}"
  end

  def is_checked?(board, color)
    moves = legal_moves((color == :white) ? :black : :white, board)
    board.king_is_taken_by?(moves.select { |move| move =~ /x/ })
  end
end

Chess.new.main if $PROGRAM_NAME == __FILE__
