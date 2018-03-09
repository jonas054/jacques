# coding: utf-8

require 'rainbow'
require_relative 'board'

# TODO:
# - Semi-smart selection of piece at pawn promotion (i.e. knight if that leads
#   to immediate checkmate)
# - Smarter selection of moves (scoring engine)
# - Opening book
ALL_DIRECTIONS =
  [-1, 0, 1].repeated_permutation(2).reject { |y, x| x == 0 && y == 0 }
ROOK_DIRECTIONS = [-1, 0, 1].repeated_permutation(2).reject do |x, y|
  x.abs == y.abs
end
KNIGHT_DIRECTIONS = [1, 2, -1, -2].permutation(2).select do |x, y|
  x.abs + y.abs == 3
end
BISHOP_DIRECTIONS = [-1, 1].repeated_permutation(2)

class Chess
  def initialize(board = nil)
    @board = board || Board.new
  end

  def setup(contents)
    @board.setup(contents)
  end

  def main(args)
    puts run(args)
  end

  def run(args = [])
    puts @board.draw
    i = -1
    positions = []
    loop do
      i += 1
      color = i.even? ? :white : :black
      turn = i / 2 + 1
      move = if args.include?('-h') && color == :white
        get_human_move(turn)
      else
        make_move(turn, color)
      end

      if move.nil?
        return is_checked?(@board, color) ? 'Checkmate' : 'Stalemate'
      end

      puts draw(move)
      return 'Draw' if @board.only_kings_left?

      positions << @board.notation
      if positions.count(@board.notation) > 2
        return 'Draw due to threefold repetition'
      end
    end
  end

  def draw(args)
    @board.draw(args)
  end

  def get_human_move(turn)
    move = nil
    loop do
      print "White move: #{turn}."
      move = $stdin.gets.chomp
      break if legal?(move)
      puts 'Illegal move'
    end
    move_piece(move)
  end

  def make_move(turn, who_to_move)
    my_moves = []
    legal_moves(who_to_move, @board,
                :is_top_level_call) do |board, row, col, new_row, new_col, take|
      add_move_if_legal(my_moves, board, row, col, new_row, new_col, take)
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

    chosen_move = (best_moves.any? ? best_moves : my_moves).sample
    puts "#{turn}.#{'..' if who_to_move == :black}#{chosen_move}"
    move_piece(chosen_move)
  end

  def move_piece(chosen_move)
    start_row, start_col = @board.get_coordinates(chosen_move[/^[a-h][1-8]/])
    new_row, new_col = @board.get_coordinates(chosen_move[/[a-h][1-8]$/])
    @board.move(start_row, start_col, new_row, new_col)
    [start_row, start_col, new_row, new_col]
  end

  def is_checking_move?(move)
    row, col = @board.get_coordinates(move[/^[a-h][1-8]/])
    new_row, new_col = @board.get_coordinates(move[/[a-h][1-8]$/])
    new_board = Board.new(@board)
    color_of_moving_piece = new_board.color_at(row, col)
    other_color = (color_of_moving_piece == :white) ? :black : :white
    new_board.move(row, col, new_row, new_col)
    is_checked?(new_board, other_color)
  end

  def is_castling_move?(move)
    row, col = @board.get_coordinates(move[/^[a-h][1-8]/])
    new_row, new_col = @board.get_coordinates(move[/[a-h][1-8]$/])
    %w[♚ ♔].include?(@board.get(row, col)) && (new_col - col).abs == 2
  end

  def legal?(move)
    row, col = @board.get_coordinates(move[/^[a-h][1-8]/])
    new_row, new_col = @board.get_coordinates(move[/[a-h][1-8]$/])
    legal_moves(@board.color_at(row, col), @board, true,
                [row, col]) do |_, _, _, nr, nc, _|
      return true if nr == new_row && nc == new_col
    end
    false
  end

  def legal_moves(who_to_move, board, is_top_level_call, only_from = nil, &block)
    Board::SIZE.times.each do |row|
      next if only_from && row != only_from[0]

      Board::SIZE.times.each do |col|
        next if only_from && col != only_from[1]

        piece_color = board.color_at(row, col)
        next unless piece_color == who_to_move

        piece = board.get(row, col)
        other_color = (piece_color == :white) ? :black : :white
        case piece
        when '♜', '♖'
          ROOK_DIRECTIONS.each do |y, x|
            (1...Board::SIZE).each do |scale|
              new_row = row + y * scale
              new_col = col + x * scale
              break if board.outside_board?(new_row, new_col)
              break if board.color_at(new_row, new_col) == piece_color
              yield board, row, col, new_row, new_col, :can_take
              break if board.color_at(new_row, new_col) == other_color
            end
          end
        when '♞', '♘'
          KNIGHT_DIRECTIONS.each do |r, c|
            unless board.outside_board?(row + r, col + c)
              yield board, row, col, row + r, col + c, :can_take
            end
          end
        when '♝', '♗'
          BISHOP_DIRECTIONS.each do |y, x|
            (1...Board::SIZE).each do |scale|
              new_row = row + y * scale
              new_col = col + x * scale
              break if board.outside_board?(new_row, new_col)
              break if board.color_at(new_row, new_col) == piece_color
              yield board, row, col, new_row, new_col, :can_take
              break if board.color_at(new_row, new_col) == other_color
            end
          end
        when '♚', '♔'
          ALL_DIRECTIONS.each do |y, x|
            unless board.outside_board?(row + y, col + x)
              yield board, row, col, row + y, col + x, :can_take
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
              yield board, row, col, new_row, new_col, :can_take
              break if board.color_at(new_row, new_col) == other_color
            end
          end
        when '♟', '♙'
          direction = (piece == '♟') ? 1 : -1
          yield board, row, col, row + direction, col, :cannot_take
          yield board, row, col, row + direction, col + 1, :must_take if col < 7
          yield board, row, col, row + direction, col - 1, :must_take if col > 0
          if row == (piece == '♟' ? 1 : 6) &&
             board.empty?(row + direction, col)
            yield board, row, col, row + 2 * direction, col, :cannot_take
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
                               unattacked_columns, rook_column, &block)
    piece_color = board.color_at(row, col)
    royalty_row = (piece_color == :white) ? 7 : 0
    return unless row == royalty_row

    rook = (piece_color == :white) ? '♖' : '♜'
    if empty_columns.all? { |x| board.empty?(row, x) } &&
       board.get(row, rook_column) == rook
      attacked = false
      other_color = (piece_color == :white) ? :black : :white
      royalty_row = (piece_color == :white) ? 7 : 0
      legal_moves(other_color, board, false) do |_, _, _, new_row, new_col, _|
        if new_row == royalty_row &&
           unattacked_columns.include?(new_col)
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
        yield board, row, col, row, king_destination, :cannot_take
      end
    end
  end

  private def add_en_passant_if_legal(board, row, col, col_delta)
    piece = board.get(row, col)
    opposite_piece = (piece == '♟') ? '♙' : '♟'
    direction = (piece == '♟') ? 1 : -1
    return unless (0..7).include?(col + col_delta)

    if board.get(row, col + col_delta) == opposite_piece &&
       board.previous.get(row + 2 * direction, col + col_delta) ==
       opposite_piece
      yield board, row, col, row + direction, col + col_delta,
            :must_take_en_passant
    end
  end

  def add_move_if_legal(result, board, row, col, new_row, new_col, take)
    taking = board.taking?(row, col, new_row, new_col) ||
             take == :must_take_en_passant
    unless @just_looking
      new_board = Board.new(board)
      color_of_moving_piece = new_board.color_at(row, col)
      new_board.move(row, col, new_row, new_col)

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
               when :must_take_en_passant
                 true # conditions already checked
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
    moves = []
    other_color = (color == :white) ? :black : :white
    legal_moves(other_color, board,
                !:is_top_level_call) do |b, row, col, new_row, new_col, take|
      add_move_if_legal(moves, b, row, col, new_row, new_col, take)
    end
    board.king_is_taken_by?(moves.select { |move| move =~ /x/ })
  end
end

Chess.new.main(ARGV) if $PROGRAM_NAME == __FILE__
