# frozen_string_literal: true

require 'pty'
require './board'

# Wrapper around the Stockfish program.
class Stockfish
  attr_writer :board

  def initialize
    @master, slave = PTY.open
    read, @write = IO.pipe
    spawn('./stockfish_20011801_x64', in: read, out: slave)
    read.close
    slave.close

    wait_for('uci', /^uciok/)
    @write.puts 'setoption name UCI_LimitStrength value true'
    @write.puts 'setoption name UCI_Elo value 1350'
  end

  def choose_move(who_to_move)
    castling_availability = '-'
    en_passant_target_square = '-'
    halfmove_clock = 0
    fullmove_number = 1

    @write.puts "position fen #{@board.fen} #{who_to_move.to_s[0]} " \
                "#{castling_availability} #{en_passant_target_square} " \
                "#{halfmove_clock} #{fullmove_number}"
    line = wait_for('go', /^bestmove/)
    move = line[/bestmove \S+/].split.last
    move == '(none)' ? nil : move[0..3]
  end

  private def wait_for(command, regexp)
    @write.puts command
    output = ''
    output = @master.gets while output !~ regexp
    output
  end
end
