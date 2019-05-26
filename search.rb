# frozen_string_literal: true

fastest = 1000
(0..100_000).each do |s|
  print "\rsrand #{s}  "
  output = `env SRAND=#{s} ruby test_chess.rb -n test_run_repetition_draw`
  output =~ /Finished in (\d+\.\d+).*/
  seconds = Regexp.last_match(1).to_f
  finish = $&
  if seconds < fastest && output =~ /0 failures/
    puts finish
    fastest = seconds
  end
end
