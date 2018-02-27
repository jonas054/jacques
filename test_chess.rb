# coding: utf-8
require 'test/unit'
require_relative 'chess'

class TestChess < Test::Unit::TestCase
  def setup
    @chess = Chess.new
    $stdout = StringIO.new
    srand 1
  end

  def teardown
    $stdout = STDOUT
  end

  def test_1
    last_move = nil
    (1..60).each do |turn|
      @chess.make_move(turn, :white)
      last_move = @chess.make_move(turn, :black)
    end
    assert_equal <<~TEXT, $stdout.string
      1.c2c4
      1...d7d5
      2.d1a4
      2...b7b5
      3.a4xb5
      3...b8d7
      4.b5xd7
      4...d8xd7
      5.c4xd5
      5...d7xd5
      6.g2g4
      6...d5xd2
      7.c1xd2
      7...c8xg4
      8.f2f4
      8...g4xe2
      9.e1xe2
      9...g7g5
      10.f4xg5
      10...a8c8
      11.e2d3
      11...c8d8
      12.d3e2
      12...d8xd2
      13.e2xd2
      13...a7a6
      14.f1b5
      14...a6xb5
      15.g1h3
      15...g8h6
      16.g5xh6
      16...f8xh6
      17.d2d1
      17...c7c6
      18.d1c2
      18...h6g7
      19.b1c3
      19...g7xc3
      20.b2xc3
      20...h8f8
      21.h1d1
      21...h7h5
      22.d1d8
      22...e8xd8
      23.a1d1
      23...d8e8
      24.d1d8
      24...e8xd8
      25.h3f2
      25...e7e6
      26.c3c4
      26...b5xc4
      27.c2c1
      27...c4c3
      28.h2h4
      28...f7f5
      29.f2e4
      29...f5xe4
      30.a2a4
      30...f8f1
      31.c1c2
      31...f1c1
      32.c2xc1
      32...d8c8
      33.a4a5
      33...c8d8
      34.a5a6
      34...c3c2
      35.c1xc2
      35...c6c5
      36.c2b2
      36...e4e3
      37.b2c1
      37...c5c4
      38.c1b1
      38...c4c3
      39.b1a2
      39...d8e8
      40.a2a1
      40...e8f7
      41.a6a7
      41...f7f8
      42.a7a8
      42...f8e7
      43.a8f8
      43...e7xf8
      44.a1a2
      44...f8e8
      45.a2b3
      45...e8e7
      46.b3xc3
      46...e7f8
      47.c3b4
      47...f8g7
      48.b4b5
      48...g7h8
      49.b5c4
      49...h8h7
      50.c4c5
      50...h7g8
      51.c5d4
      51...e6e5
      52.d4xe3
      52...g8g7
      53.e3f2
      53...g7h7
      54.f2e2
      54...e5e4
      55.e2d2
      55...e4e3
      56.d2xe3
      56...h7g6
      57.e3e2
      57...g6f7
      58.e2d3
      58...f7g8
      59.d3e4
      59...g8h8
      60.e4f3
      60...h8g8
    TEXT
    Rainbow.enabled = false  
    assert_equal ("8                   ♚    \n" +
                  "7                        \n" +
                  "6                        \n" +
                  "5                      ♟ \n" +
                  "4                      ♙ \n" +
                  "3                ♔       \n" +
                  "2                        \n" +
                  "1                        \n" +
                  "  a  b  c  d  e  f  g  h\n"), @chess.draw(last_move)
  end
end
