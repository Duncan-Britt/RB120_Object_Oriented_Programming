require 'pry'

module FormatIO
  LINE_LENGTH = 70
  CURSOR_SPACE = LINE_LENGTH/5
  def puts(message)
    super "#{message.center(LINE_LENGTH)}"
  end

  def gets
    print "#{" " * (CURSOR_SPACE)}=> "
    super
  end
end

class Board
  attr_reader :squares

  include FormatIO

  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns
                  [[1, 5, 9], [3, 5, 7]]              # diagonals

  def initialize(squares={}, dupl=false)
    @squares = squares
    reset unless dupl
  end

  def dup
    new_squares = {}
    (1..9).each do |key|
      new_squares[key] = Square.new
      new_squares[key].marker = @squares[key].marker
    end

    Board.new(new_squares, true)
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
  attr_accessor :score, :marker

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
    get_names
    set_markers
    set_difficulty
    clear
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

  def get_names
    puts "Enter your name:"
    loop do
      self.username = gets.chomp
      break unless username.empty?
      puts "You must enter a name."
    end
    puts "Enter a name for your opponent:"
    loop do
      self.computer_name = gets.chomp
      break unless computer_name.empty?
      puts "You must enter a name."
    end

  end

  def set_markers
    puts "Would you like to set custom markers for the tournament? (y/n)"
    answer = nil
    loop do
      answer = gets.chomp.downcase
      break if answer == 'y' or answer == 'n'
      puts "Input must be 'y' or 'n'"
    end
    case answer
    when 'y'
      choose_markers
    end
  end

  def choose_markers
    puts "Choose your marker"
    mark = nil
    loop do
      mark = gets.chomp
      break if mark.length == 1
      puts "Invalid input. Marker must be 1 character"
    end
    human.marker = mark
    puts "Choose computer marker"
    loop do
      mark = gets.chomp
      break if mark.length == 1
      puts "Invalid input. Marker must be 1 character"
    end
    computer.marker = mark
  end

  def set_difficulty
    puts "Please select a difficulty level for the tournament:\n"
    puts "Easy (e)\n"
    puts "Medium (m)\n"
    puts "Impossible(i)"

    case get_difficulty
    when 'e'
      @move_methods[1] = Proc.new { easy_moves }
    when 'm'
      @move_methods[1] = Proc.new { medium_moves }
    when 'i'
      @move_methods[1] = Proc.new { unbeatable_moves }
    end
  end

  def get_difficulty
    difficulty = nil
    loop do
      difficulty = gets.chomp.downcase
      break if difficulty == 'e' || difficulty == 'm' || difficulty == 'i'
      puts "Input must be 'e', 'm', or 'i'\n"
    end
    difficulty
  end

  def play_tournament_again?
    answer = nil
    loop do
      puts "Would you like to play another tournament? (y/n)"
      answer = gets.chomp.downcase
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
    self.starting_player_idx = FIRST_TO_MOVE_IDX
    reset
    human.score = 0
    computer.score = 0
    self.tournament_won = false
    set_difficulty
    set_markers
    clear
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
      alternate_starting_player
      reset
      display_play_again_message
    end
  end

  def alternate_starting_player
    self.starting_player_idx = (starting_player_idx + 1) % 2
  end

  def player_move
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  attr_reader :board, :human, :computer
  attr_accessor :tournament_won, :starting_player_idx, :username, :computer_name

  def initialize
    @board = Board.new
    @human = Player.new(HUMAN_MARKER)
    @computer = Player.new(COMPUTER_MARKER)
    @move_methods = [Proc.new { human_moves }, Proc.new { computer_moves }]
    @turn_idx = FIRST_TO_MOVE_IDX
    @starting_player_idx = FIRST_TO_MOVE_IDX
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
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice."
    end

    board[square] = human.marker
  end

  def easy_moves
    board[board.unmarked_keys.sample] = computer.marker
  end

  def medium_moves
    choice = if immediate_win
               immediate_win
             elsif immediate_threat
               immediate_threat
             else
               board.unmarked_keys.sample
             end
    board[choice] = computer.marker
  end

  def immediate_threat
    Board::WINNING_LINES.each do |line|
      count = 0
      choice = nil
      line.each do |key|
        count += 1 if board.squares[key].marker == human.marker
        choice = key if board.unmarked_keys.include?(key)
      end
      if count == 2 && choice
        return choice
      end
    end
    nil
  end

  def immediate_win
    Board::WINNING_LINES.each do |line|
      count = 0
      choice = nil
      line.each do |key|
        if board.squares[key].marker == computer.marker
          count += 1
        else
          choice = key
        end
      end

      if count == 2 && board.unmarked_keys.include?(choice)
        return choice
      end
    end
    nil
  end

  def unbeatable_moves
    if immediate_win
      board[immediate_win] = computer.marker
    else
      t1 = Thread.new {
        brd = board.dup
        choice, score = minimax(computer, brd)
        board[choice] = computer.marker
      }
      t2 = Thread.new {
        spinner = Enumerator.new do |e|
          loop do
            e.yield '|'
            e.yield '/'
            e.yield '-'
            e.yield '\\'
          end
        end
        loop do |i|
          break unless t1.alive?
          printf("\r%sLOADING %s ", ' '*FormatIO::CURSOR_SPACE, spinner.next)
          sleep(0.1)
        end
      }
      t1.join
      t2.join
    end
  end

  def get_score(player, brd)
    case brd.winning_marker
    when player.marker
      binding.pry
      # this is unnecessary, FIXME
      -10
    when nil
      0
    else
      10
    end
  end

  def minimax(player, brd)
    if brd.someone_won? || brd.full?
      if brd.winning_marker == "O" && player == computer
        binding.pry
      end
      return nil, get_score(player, brd)
    end

    available_keys = []
    scores = []
    brd.unmarked_keys.each do |key|
      available_keys << key
      bord = brd.dup
      bord[key] = player.marker
      if player == computer
        a, b = minimax(human, bord)
        scores << b
      else
        a, b = minimax(computer, bord)
        scores << b
      end
    end

    choices = []
    best = -10
    scores.each_with_index do |e, i|
      if e > best
        choices = [i]
        best = e
      elsif e == best
        choices << i
      end
    end

    choice = choices.sample
    case scores[choice]
    when 10
      points = -10
    when -10
      points = 10
    else
      points = 0
    end
    return available_keys[choice], points
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
      answer = gets.chomp.downcase
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
    @turn_idx = starting_player_idx
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
