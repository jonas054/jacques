# coding: utf-8
require 'rainbow'
require_relative 'board'

ALL_DIRECTIONS =
  [-1, 0, 1].repeated_permutation(2).reject { |y, x| x == 0 && y == 0 }
ROOK_DIRECTIONS = [-1, 0, 1].repeated_permutation(2).reject do |x, y|
  x.abs == y.abs
end

class Chess
  def main
    @board = Board.new
    @board.draw
    80.times do |i|
      color = i.even? ? :white : :black
      move = make_move(i / 2 + 1, color)
      @board.draw(move)
    end
  end

  def make_move(turn, who_to_move)
    my_moves = legal_moves(who_to_move)
    raise "No legal moves found for #{who_to_move}" if my_moves.empty?

    taking_moves = my_moves.select { |move| move =~ /x/ }
    if @board.king_can_be_taken_by?(who_to_move, taking_moves)
      raise "King taken by #{who_to_move}!"
    end

    chosen_move = (taking_moves.any? ? taking_moves : my_moves).sample
    puts "#{turn}.#{'..' if who_to_move == :black}#{chosen_move}"
    start_row, start_col = @board.get_coordinates(chosen_move[0, 2])
    new_row, new_col = @board.get_coordinates(chosen_move[-2..-1])
    @board.move(start_row, start_col, new_row, new_col)
    [start_row, start_col, new_row, new_col]
  end

  def legal_moves(who_to_move)
    result = []
    Board::SIZE.times.each do |row|
      Board::SIZE.times.each do |col|
        piece = @board.get(row, col)
        piece_color = if Board::WHITE_PIECES.include?(piece)
                        :white
                      elsif Board::BLACK_PIECES.include?(piece)
                        :black
                      else
                        :none
                      end
        next unless piece_color == who_to_move
        other_color = (piece_color == :white) ? :black : :white
        case piece
        when '♜', '♖'
          ROOK_DIRECTIONS.each do |y, x|
            (1...Board::SIZE).each do |scale|
              new_row = row + y * scale
              new_col = col + x * scale
              break if @board.outside_board?(new_row, new_col)
              break if @board.color_at?(piece_color, new_row, new_col)
              add_move_if_legal(result, row, col, new_row, new_col)
              break if @board.color_at?(other_color, new_row, new_col)
            end
          end
        when '♞', '♘'
          [1, 2, -1, -2].permutation(2).select do |x, y|
            x.abs + y.abs == 3
          end.each do |r, c|
            add_move_if_legal(result, row, col, row + r, col + c)
          end
        when '♝', '♗'
          [-1, 1].repeated_permutation(2).each do |y, x|
            (1...Board::SIZE).each do |scale|
              new_row = row + y * scale
              new_col = col + x * scale
              break if @board.outside_board?(new_row, new_col)
              break if @board.color_at?(piece_color, new_row, new_col)
              add_move_if_legal(result, row, col, new_row, new_col)
              break if @board.color_at?(other_color, new_row, new_col)
            end
          end
        when '♚', '♔'
          ALL_DIRECTIONS.each do |y, x|
            add_move_if_legal(result, row, col, row + y, col + x)
          end
        when '♛', '♕'
          ALL_DIRECTIONS.each do |y, x|
            (1...Board::SIZE).each do |scale|
              new_row = row + y * scale
              new_col = col + x * scale
              break if @board.outside_board?(new_row, new_col)
              break if @board.color_at?(piece_color, new_row, new_col)
              add_move_if_legal(result, row, col, new_row, new_col)
              break if @board.color_at?(other_color, new_row, new_col)
            end
          end
        when '♟', '♙'
          direction = piece == '♟' ? 1 : -1
          add_move_if_legal(result, row, col, row + direction, col,
                            :cannot_take)
          add_move_if_legal(result, row, col, row + direction, col + 1,
                            :must_take)
          add_move_if_legal(result, row, col, row + direction, col - 1,
                            :must_take)
          if row == (piece == '♟' ? 1 : 6) &&
             @board.empty?(row + direction, col)
            add_move_if_legal(result, row, col, row + 2 * direction, col,
                              :cannot_take)
          end
        end
      end
    end
    result
  end

  def add_move_if_legal(result, row, col, new_row, new_col, take = :can_take)
    return if @board.outside_board?(new_row, new_col)
    taking = @board.taking?(row, col, new_row, new_col)
    is_legal = case take
               when :cannot_take
                 @board.empty?(new_row, new_col)
               when :must_take
                 taking
               when :can_take
                 @board.empty?(new_row, new_col) || taking
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
end

Chess.new.main
