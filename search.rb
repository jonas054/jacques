# frozen_string_literal: true

(1..100_000).each do |s|
  print "\rsrand #{s}  "
  output = `env SRAND=#{s} ruby test_chess.rb -n test_run_draw`
  output =~ /Finished in (\d+)\..*/
  puts '', output if Regexp.last_match(1).length < 2 && output =~ /0 failures/
end
