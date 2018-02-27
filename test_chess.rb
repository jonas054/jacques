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
      2.c4xd5
      2...d8xd5
      3.h2h3
      3...c8xh3
      4.g1xh3
      4...d5xd2
      5.e1xd2
      5...b8d7
      6.g2g3
      6...a8c8
      7.d2e1
      7...a7a5
      8.d1xd7
      8...e8xd7
      9.b1c3
      9...b7b6
      10.e1d1
      10...g7g5
      11.h3xg5
      11...f8h6
      12.h1xh6
      12...g8xh6
      13.g5xh7
      13...h8xh7
      14.c1xh6
      14...h7xh6
      15.e2e4
      15...h6h3
      16.f1xh3
      16...d7c6
      17.h3xc8
      17...b6b5
      18.c3xb5
      18...c6xb5
      19.f2f4
      19...e7e6
      20.c8xe6
      20...f7xe6
      21.a2a4
      21...b5b6
      22.f4f5
      22...e6xf5
      23.e4xf5
      23...b6c5
      24.f5f6
      24...c5c4
      25.d1d2
      25...c7c5
      26.d2c1
      26...c4b4
      27.g3g4
      27...c5c4
      28.g4g5
      28...b4c5
      29.c1d2
      29...c5d4
      30.a1f1
      30...d4d5
      31.d2c1
      31...d5e4
      32.c1d1
      32...e4d4
      33.d1e2
      33...d4c5
      34.b2b4
      34...a5xb4
      35.f1a1
      35...c5d5
      36.a1b1
      36...d5e5
      37.b1xb4
      37...e5d6
      38.b4xc4
      38...d6e6
      39.e2d2
      39...e6f7
      40.d2c2
      40...f7e8
      41.c4c6
      41...e8f8
      42.c2b2
      42...f8f7
      43.c6c4
      43...f7g8
      44.c4d4
      44...g8f7
      45.d4f4
      45...f7e6
      46.f4b4
      46...e6f5
      47.b4b6
      47...f5xg5
      48.b6e6
      48...g5h6
      49.b2b1
      49...h6g5
      50.e6e3
      50...g5xf6
      51.a4a5
      51...f6g6
      52.e3f3
      52...g6h7
      53.f3d3
      53...h7g6
      54.d3f3
      54...g6g7
      55.f3f4
      55...g7h8
      56.f4f2
      56...h8g8
      57.f2h2
      57...g8g7
      58.h2h8
      58...g7xh8
      59.b1b2
      59...h8g8
      60.b2c2
      60...g8g7
    TEXT
    Rainbow.enabled = false  
    assert_equal ("8                        \n" +
                  "7                   ♚    \n" +
                  "6                        \n" +
                  "5 ♙                      \n" +
                  "4                        \n" +
                  "3                        \n" +
                  "2       ♔                \n" +
                  "1                        \n" +
                  "  a  b  c  d  e  f  g  h\n"), @chess.draw(last_move)
  end
end
