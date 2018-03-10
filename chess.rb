# coding: utf-8
# frozen_string_literal: true

require 'rainbow'
require_relative 'board'
require_relative 'rule_book'

# TODO: These.
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

Coord = Struct.new(:row, :col)

# The main driver of the chess engine.
class Chess
  def initialize(board = nil)
    @board = board || Board.new
    @rules = RuleBook.new
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
    @rules.legal_moves(who_to_move, @board,
                       :is_top_level_call) do |board, coord, new_coord, take|
      add_move_if_legal(my_moves, board, coord, new_coord, take)
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
        m.end_with?(position(new_coord.row, new_coord.col))
      end
      chosen_moves -= dangerous if dangerous.size < chosen_moves.size
    end
    chosen_move = chosen_moves.sample
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
    _, new_col = @board.get_coordinates(move[/[a-h][1-8]$/])
    %w[♚ ♔].include?(@board.get(row, col)) && (new_col - col).abs == 2
  end

  def legal?(move)
    row, col = @board.get_coordinates(move[/^[a-h][1-8]/])
    new_row, new_col = @board.get_coordinates(move[/[a-h][1-8]$/])
    @rules.legal_moves(@board.color_at(row, col), @board, true,
                       [row, col]) do |_, _, new_coord, _|
      return true if new_coord.row == new_row && new_coord.col == new_col
    end
    false
  end

  def add_move_if_legal(result, board, coord, new_coord, take)
    taking = take == :must_take_en_passant ||
             board.taking?(coord.row, coord.col, new_coord.row, new_coord.col)
    unless @just_looking
      new_board = Board.new(board)
      color_of_moving_piece = new_board.color_at(coord.row, coord.col)
      new_board.move(coord.row, coord.col, new_coord.row, new_coord.col)

      @just_looking = true
      is_checked = is_checked?(new_board, color_of_moving_piece)
      @just_looking = false
      return if is_checked
    end

    is_legal = case take
               when :cannot_take
                 board.empty?(new_coord.row, new_coord.col)
               when :must_take
                 taking
               when :can_take
                 board.empty?(new_coord.row, new_coord.col) || taking
               when :must_take_en_passant
                 true # conditions already checked
               end
    if is_legal
      result << (position(coord.row, coord.col) + (taking ? 'x' : '') +
                 position(new_coord.row, new_coord.col))
    end
  end

  # Converts 1, 2 into "b6".
  def position(row, col)
    "#{'abcdefgh'[col]}#{Board::SIZE - row}"
  end

  def is_checked?(board, color)
    moves = []
    other_color = (color == :white) ? :black : :white
    @rules.legal_moves(other_color, board,
                       # This is not a condition! How is this a condition?
                       # rubocop:disable Lint/LiteralAsCondition
                       !:is_top_level_call) do |b, coord, new_coord, take|
      # rubocop:enable Lint/LiteralAsCondition
      add_move_if_legal(moves, b, coord, new_coord, take)
    end
    board.king_is_taken_by?(moves.select { |move| move =~ /x/ })
  end
end

Chess.new.main(ARGV) if $PROGRAM_NAME == __FILE__
