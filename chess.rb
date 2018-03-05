# coding: utf-8

require 'rainbow'
require_relative 'board'

# TODO:
# - Castling
# - Semi-smart selection of piece at pawn promotion (i.e. knight if that leads
#   to immediate checkmate)
# - Smarter selection of moves (scoring engine)
# - Opening book
# - Human opponent
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

  def main
    puts run
  end

  def run
    puts @board.draw
    i = -1
    positions = []
    loop do
      i += 1
      color = i.even? ? :white : :black
      move = make_move(i / 2 + 1, color)

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

  def legal_moves(who_to_move, board, is_top_level_call, &block)
    Board::SIZE.times.each do |row|
      Board::SIZE.times.each do |col|
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
            yield board, row, col, row + r, col + c, :can_take
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
            yield board, row, col, row + y, col + x, :can_take
          end
          # 1. Kungen får inte stå i schack; man kan alltså inte undkomma en
          # schack genom att rockera.
          # 2. TODO: Varken kungen eller det torn som används för rockaden får
          # ha flyttats tidigare under partiet.
          # 3. Inget fält mellan kungen och tornet får vara besatt av en annan
          # pjäs; det får alltså inte stå någon annan pjäs emellan dem, oavsett
          # färg.
          # 4. TODO: Inget av de fält som kungen rör sig över, eller hamnar på,
          # får vara hotat av någon av motståndarens pjäser; man kan alltså
          # inte flytta in i schack.
          if is_top_level_call && col == 4
            royalty_row = (piece == '♔') ? 7 : 0
            if row == royalty_row
              rook = (piece == '♔') ? '♖' : '♜'
              # King-side castle
              if board.empty?(row, 5) && board.empty?(row, 6) &&
                 board.get(row, 7) == rook
                attacked = false
                legal_moves(other_color, board,
                            false) do |_, _, _, new_row, new_col, _|
                  if new_row == royalty_row && (4..6).include?(new_col)
                    attacked = true
                    break
                  end
                end

                unless attacked ||
                       board.king_has_moved?(piece_color) ||
                       board.king_side_rook_has_moved?(piece_color)
                  yield board, row, col, row, col + 2, :cannot_take
                end
              end
              # Queen-side castle
              if board.empty?(row, 3) && board.empty?(row, 2) &&
                 board.empty?(row, 1) && board.get(row, 0) == rook
                attacked = false
                legal_moves(other_color, board,
                            false) do |_, _, _, new_row, new_col, _|
                  if new_row == royalty_row && (1..4).include?(new_col)
                    attacked = true
                    break
                  end
                end

                unless attacked ||
                       board.king_has_moved?(piece_color) ||
                       board.queen_side_rook_has_moved?(piece_color)
                  yield board, row, col, row, col - 2, :cannot_take
                end
              end
            end
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
          yield board, row, col, row + direction, col + 1, :must_take
          yield board, row, col, row + direction, col - 1, :must_take
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
    return if board.outside_board?(new_row, new_col)
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

Chess.new.main if $PROGRAM_NAME == __FILE__
