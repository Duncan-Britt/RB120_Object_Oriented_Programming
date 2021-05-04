require 'pry'

module FormatIO
  LINE_LENGTH = 70
  CURSOR_SPACE = LINE_LENGTH/5
  def puts(message)
    super "#{message.center(LINE_LENGTH)}"
  end

  def get_input
    print "#{" " * (CURSOR_SPACE)}=> "
    gets
  end
end

class Board
  attr_reader :squares

  include FormatIO

  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns
                  [[1, 5, 9], [3, 5, 7]]              # diagonals

  def initialize
    @squares = {}
    reset
  end

  def set_square_at(key, marker)
    @squares[key].marker = marker
  end

  def []=(key, marker)
    @squares[key].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
    @initial = Square.new.marker
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    puts "     |     |     "
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}  "
    puts "     |     |     "
    puts "-----+-----+-----"
    puts "     |     |     "
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}  "
    puts "     |     |     "
    puts "-----+-----+-----"
    puts "     |     |     "
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}  "
    puts "     |     |     "
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return false if markers.size != 3
    markers.min == markers.max
  end
end

class Square
  INITIAL_MARKER = " "

  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def marked?
    marker != INITIAL_MARKER
  end

  def unmarked?
    marker == INITIAL_MARKER
  end
end

class Player
  attr_reader :marker
  attr_accessor :score

  def initialize(marker)
    @marker = marker
    @score = 0
  end
end

class TTTGame
  include FormatIO

  HUMAN_MARKER = "X"
  COMPUTER_MARKER = "O"
  FIRST_TO_MOVE_IDX = 0
  WIN_CONDITION = 5

  def play
    clear
    display_welcome_message
    loop do
      run_games
      break unless tournament_won
      display_tournament_result
      break unless play_tournament_again?
      reset_tournament
      display_play_again_message
    end
    display_goodbye_message
  end

  private

  def play_tournament_again?
    answer = nil
    loop do
      puts "Would you like to play another tournament? (y/n)"
      answer = get_input.chomp.downcase
      break if %w(y n).include? answer
      puts "Sorry, must be y or n"
    end
    answer == 'y'
  end

  def tournament_over?
    human.score == WIN_CONDITION || computer.score == WIN_CONDITION
  end

  def display_tournament_result
    if human.score == WIN_CONDITION
      puts "You won the tournament!"
    else
      puts "Computer won the tournament!"
    end
  end

  def reset_tournament
    reset
    human.score = 0
    computer.score = 0
    self.tournament_won = false
  end

  def run_games
    loop do
      display_board
      player_move
      display_result
      if tournament_over?
        self.tournament_won = true
        break
      end
      break unless play_again?
      reset
      display_play_again_message
    end
  end

  def player_move
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  attr_reader :board, :human, :computer
  attr_accessor :tournament_won

  def initialize
    @board = Board.new
    @human = Player.new(HUMAN_MARKER)
    @computer = Player.new(COMPUTER_MARKER)
    @move_methods = [Proc.new { human_moves }, Proc.new { defensive_computer_moves }]
    @turn_idx = FIRST_TO_MOVE_IDX
    @tournament_won = false
  end

  def display_welcome_message
    puts ""
    puts "Welcome to Tic Tac Toe!"
    puts "First player to win #{WIN_CONDITION} round wins the tournament!"
    puts ""
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def display_board
    puts ""
    puts "You're a #{human.marker}. Computer is a #{computer.marker}"
    puts "Your score: #{human.score}. Computer score: #{computer.score}"
    puts ""
    board.draw
    puts ""
  end

  def joinor(arr, delim=',', last='or')
    if arr.size == 1
      "#{arr[0]}"
    elsif arr.size == 2
      arr.join(" #{last} ")
    else
      "#{arr[0..-2].join("#{delim} ")}#{delim} #{last} #{arr[-1]}"
    end
  end

  def human_moves
    puts "Choose a square (#{joinor(board.unmarked_keys)}): "
    square = nil
    loop do
      square = get_input.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice."
    end

    board[square] = human.marker
  end

  # def computer_moves
  #   board[board.unmarked_keys.sample] = computer.marker
  # end

  def defensive_computer_moves
    choice = board.unmarked_keys.sample
    Board::WINNING_LINES.each do |line|
      count = 0
      unmarked = nil
      line.each do |key|
        count += 1 if board.squares[key].marker == human.marker
        unmarked = key if board.unmarked_keys.include?(key)
      end
      if count == 2 && unmarked
        choice = unmarked
        break
      end
    end
    board[choice] = computer.marker
  end

  def display_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      puts 'You won!'
      human.score += 1
    when computer.marker
      puts "Computer won!"
      computer.score += 1
    else
      puts "It's a tie."
    end
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = get_input.chomp.downcase
      break if %w(y n).include? answer
      puts "Sorry, must be y or n"
    end

    answer == 'y'
  end

  def clear
    system 'clear'
  end

  def reset
    board.reset
    @turn_idx = FIRST_TO_MOVE_IDX
    clear
  end

  def display_play_again_message
    puts ""
    puts "Let's play again!"
    puts ""
  end

  def current_player_moves
    @move_methods[@turn_idx].call
    switch_current_method
  end

  def switch_current_method
    @turn_idx = (@turn_idx + 1) % 2
  end

  def human_turn?
    @turn_idx == 0
  end
end

game = TTTGame.new
game.play
