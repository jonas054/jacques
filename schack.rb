# coding: utf-8
require 'rainbow'

WHITE_PIECES = '♔♕♖♗♘♙'.freeze
BLACK_PIECES = '♜♞♝♛♚♟'.freeze
EMPTY_ROW = [' '] * 8
INITIAL_ROW_OF_PIECES =
  %i[rook knight bishop queen king bishop knight rook].freeze
ALL_DIRECTIONS =
  [-1, 0, 1].repeated_permutation(2).reject { |y, x| x == 0 && y == 0 }
ROOK_DIRECTIONS = [-1, 0, 1].repeated_permutation(2).reject do |x, y|
  x.abs == y.abs
end

INITIAL_BOARD =
  [['♜', '♞', '♝', '♛', '♚', '♝', '♞', '♜'],
   ['♟', '♟', '♟', '♟', '♟', '♟', '♟', '♟'],
   [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
   [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
   [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
   [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
   ['♙', '♙', '♙', '♙', '♙', '♙', '♙', '♙'],
   ['♖', '♘', '♗', '♕', '♔', '♗', '♘', '♖']].freeze
EMPTY_SQUARE = ' '.freeze

class Chess
  def main
    @board = INITIAL_BOARD
    draw_board
    80.times do |i|
      color = i.even? ? :white : :black
      move = make_move(i / 2 + 1, color)
      draw_board(move)
    end
  end

  def draw_board(last_move = [])
    8.times do |row|
      print 8 - row
      8.times do |col|
        square_color = col % 2 == row % 2 ? :ghostwhite : :gray
        if row == last_move[0] && col == last_move[1] ||
           row == last_move[2] && col == last_move[3]
          square_color = :yellow
        end
        print Rainbow(" #{@board[row][col]} ").bg(square_color)
      end
      puts
    end
    puts '  a  b  c  d  e  f  g  h'
  end

  def make_move(turn, who_to_move)
    my_moves = legal_moves(who_to_move)
    raise "No legal moves found for #{who_to_move}" if my_moves.empty?

    taking_moves = my_moves.select { |move| move =~ /x/ }
    if king_can_be_taken_by?(who_to_move, taking_moves)
      raise "King taken by #{who_to_move}!"
    end

    chosen_move = (taking_moves.any? ? taking_moves : my_moves).sample
    puts "#{turn}.#{'..' if who_to_move == :black}#{chosen_move}"
    start_row, start_col = get_coordinates(chosen_move[0, 2])
    new_row, new_col = get_coordinates(chosen_move[-2..-1])
    @board[new_row][new_col] = @board[start_row][start_col]
    @board[start_row][start_col] = EMPTY_SQUARE
    [start_row, start_col, new_row, new_col]
  end

  def king_can_be_taken_by?(who_to_move, taking_moves)
    other_king = (who_to_move == :white) ? '♚' : '♔'
    king_taken = taking_moves.any? do |move|
      row, col = get_coordinates(move[-2..-1])
      @board[row][col] == other_king
    end
  end

  def get_coordinates(pos)
    [8 - pos[1].to_i, pos[0].ord - 'a'.ord]
  end

  def legal_moves(who_to_move)
    result = []
    8.times.each do |row|
      8.times.each do |col|
        piece = @board[row][col]
        piece_color = if WHITE_PIECES.include?(piece)
                        :white
                      elsif BLACK_PIECES.include?(piece)
                        :black
                      else
                        :none
                      end
        next unless piece_color == who_to_move
        other_color = (piece_color == :white) ? :black : :white
        case piece
        when '♜', '♖'
          ROOK_DIRECTIONS.each do |y, x|
            (1..7).each do |scale|
              new_row = row + y * scale
              new_col = col + x * scale
              break if outside_board?(new_row, new_col)
              break if color_at?(piece_color, position(new_row, new_col))
              add_move_if_legal(result, row, col, new_row, new_col)
              break if color_at?(other_color, position(new_row, new_col))
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
            (1..7).each do |scale|
              new_row = row + y * scale
              new_col = col + x * scale
              break if outside_board?(new_row, new_col)
              break if color_at?(piece_color, position(new_row, new_col))
              add_move_if_legal(result, row, col, new_row, new_col)
              break if color_at?(other_color, position(new_row, new_col))
            end
          end
        when '♚', '♔'
          ALL_DIRECTIONS.each do |y, x|
            add_move_if_legal(result, row, col, row + y, col + x)
          end
        when '♛', '♕'
          ALL_DIRECTIONS.each do |y, x|
            (1..7).each do |scale|
              new_row = row + y * scale
              new_col = col + x * scale
              break if outside_board?(new_row, new_col)
              break if color_at?(piece_color, position(new_row, new_col))
              add_move_if_legal(result, row, col, new_row, new_col)
              break if color_at?(other_color, position(new_row, new_col))
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
          if row == (piece == '♟' ? 1 : 6) && empty?(row + direction, col)
            add_move_if_legal(result, row, col, row + 2 * direction, col,
                              :cannot_take)
          end
        end
      end
    end
    result
  end

  def color_at?(color, pos)
    row, col = get_coordinates(pos)
    pieces = (color == :white) ? WHITE_PIECES : BLACK_PIECES
    pieces.include?(@board[row][col])
  end

  def add_move_if_legal(result, row, col, new_row, new_col, take = :can_take)
    return if outside_board?(new_row, new_col)
    taking = taking?(row, col, new_row, new_col)
    is_legal = case take
               when :cannot_take
                 empty?(new_row, new_col)
               when :must_take
                 taking
               when :can_take
                 empty?(new_row, new_col) || taking
               end
    if is_legal
      result << (position(row, col) + (taking ? 'x' : '') +
                 position(new_row, new_col))
    end
  end

  def taking?(row, col, new_row, new_col)
    WHITE_PIECES.include?(@board[row][col]) &&
      BLACK_PIECES.include?(@board[new_row][new_col]) ||
      BLACK_PIECES.include?(@board[row][col]) &&
      WHITE_PIECES.include?(@board[new_row][new_col])
  end

  def empty?(row, col)
    @board[row][col] == EMPTY_SQUARE
  end

  def outside_board?(row, col)
    row < 0 || row > 7 || col < 0 || col > 7
  end

  def position(row, col)
    "#{'abcdefgh'[col]}#{8 - row}"
  end
end

Chess.new.main
