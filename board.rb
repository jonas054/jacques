# coding: utf-8
class Board
  SIZE = 8
  INITIAL_BOARD = ['♜♞♝♛♚♝♞♜',
                   '♟♟♟♟♟♟♟♟',
                   '        ',
                   '        ',
                   '        ',
                   '        ',
                   '♙♙♙♙♙♙♙♙',
                   '♖♘♗♕♔♗♘♖'].freeze
  EMPTY_SQUARE = ' '.freeze
  WHITE_PIECES = '♔♕♖♗♘♙'.freeze
  BLACK_PIECES = '♜♞♝♛♚♟'.freeze

  def initialize
    @squares = INITIAL_BOARD
  end

  def get(row, col)
    @squares[row][col]
  end

  def empty?(row, col)
    get(row, col) == EMPTY_SQUARE
  end

  def outside_board?(row, col)
    row < 0 || row >= Board::SIZE || col < 0 || col >= Board::SIZE
  end

  def color_at?(color, row, col)
    pieces = (color == :white) ? WHITE_PIECES : BLACK_PIECES
    pieces.include?(get(row, col))
  end

  def taking?(row, col, new_row, new_col)
    WHITE_PIECES.include?(get(row, col)) &&
      BLACK_PIECES.include?(get(new_row, new_col)) ||
      BLACK_PIECES.include?(get(row, col)) &&
      WHITE_PIECES.include?(get(new_row, new_col))
  end

  def move(start_row, start_col, new_row, new_col)
    @squares[new_row][new_col] = @squares[start_row][start_col]
    @squares[start_row][start_col] = EMPTY_SQUARE
  end

  def draw(last_move = [])
    SIZE.times do |row|
      print SIZE - row
      SIZE.times do |col|
        square_color = col % 2 == row % 2 ? :ghostwhite : :gray
        if row == last_move[0] && col == last_move[1] ||
           row == last_move[2] && col == last_move[3]
          square_color = :yellow
        end
        print Rainbow(" #{@squares[row][col]} ").bg(square_color).fg(:black)
      end
      puts
    end
    puts '  a  b  c  d  e  f  g  h'
  end

  def king_can_be_taken_by?(who_to_move, taking_moves)
    other_king = (who_to_move == :white) ? '♚' : '♔'
    king_taken = taking_moves.any? do |move|
      row, col = get_coordinates(move[-2..-1])
      get(row, col) == other_king
    end
  end

  def get_coordinates(pos)
    [SIZE - pos[1].to_i, pos[0].ord - 'a'.ord]
  end
end
