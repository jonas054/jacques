# coding: utf-8
# frozen_string_literal: true

require 'rainbow'
require_relative 'board'
require_relative 'rule_book'
require_relative 'brain'

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

# The main driver of the chess engine.
class Chess
  def initialize(brain, board = nil)
    @board = board || Board.new
    @brain = brain
    @brain.board = @board
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
      result = run_one_turn(args, i, positions)
      return result if result
    end
  end

  private def run_one_turn(args, index, positions)
    color = index.even? ? :white : :black
    turn = index / 2 + 1 # /
    move = if args.include?('-h') && color == :white
             get_human_move(turn)
           else
             make_move(turn, color)
           end

    if move.nil?
      return @board.is_checked?(color) ? 'Checkmate' : 'Stalemate'
    end

    puts draw(move)
    return 'Draw' if @board.only_kings_left?

    positions << @board.notation
    if positions.count(@board.notation) > 2
      return 'Draw due to threefold repetition'
    end

    nil
  end

  def draw(args)
    @board.draw(args)
  end

  def get_human_move(turn)
    computer_move = @brain.choose_move(:white)
    return nil if computer_move.nil?

    move = nil
    loop do
      print "White move: #{turn}."
      move = $stdin.gets.chomp
      break if legal?(move)
      puts 'Illegal move'
    end
    @board.move_piece(move)
  end

  def make_move(turn, who_to_move)
    chosen_move = @brain.choose_move(who_to_move)
    return nil if chosen_move.nil?
    puts "#{turn}.#{'..' if who_to_move == :black}#{chosen_move}"
    @board.move_piece(chosen_move)
  end

  def legal?(move)
    row, col = @board.get_coordinates(move[/^[a-h][1-8]/])
    new_row, new_col = @board.get_coordinates(move[/[a-h][1-8]$/])
    RuleBook.legal_moves(@board.color_at(row, col), @board, true,
                         [row, col]) do |_, new_coord, _|
      return true if new_coord.row == new_row && new_coord.col == new_col
    end
    false
  end
end

Chess.new(Brain.new).main(ARGV) if $PROGRAM_NAME == __FILE__
