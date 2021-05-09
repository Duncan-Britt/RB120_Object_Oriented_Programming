require 'pry'

class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red; colorize(31) end
end

module FormatIO
  LINE_LENGTH = 70
  CURSOR_SPACE = LINE_LENGTH / 5
  def puts(message, red: false)
    if red
      super message.center(LINE_LENGTH).red
    else
      super message.center(LINE_LENGTH)
    end
  end

  def gets
    print "#{' ' * (CURSOR_SPACE)}=> ".red
    super
  end
end

module Loadable
  def load(method)
    t1 = Thread.new do
      method.call
    end
    t2 = Thread.new do
      spin(t1)
    end
    t1.join
    t2.join
  end

  def spin(thread)
    spinner = make_spinner

    loop do
      break unless thread.alive?
      printf("\r%s%s %s ",
             ' ' * FormatIO::CURSOR_SPACE,
             'LOADING'.red,
             spinner.next)
      sleep(0.1)
    end
    print "\r"
  end

  def make_spinner
    Enumerator.new do |e|
      loop do
        e.yield '|'.red
        e.yield '/'.red
        e.yield '-'.red
        e.yield '\\'.red
      end
    end
  end
end

class Board
  attr_reader :squares

  include FormatIO

  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns
                  [[1, 5, 9], [3, 5, 7]]              # diagonals

  def initialize(squares={}, dupl: false)
    @squares = squares
    reset unless dupl
  end

  def dup
    new_squares = {}
    (1..9).each do |key|
      new_squares[key] = Square.new
      new_squares[key].marker = @squares[key].marker
    end

    Board.new(new_squares, dupl: true)
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
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    puts "     |     |     "
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}  "
    puts "     |     |     "
    puts "-----+-----+-----"
    puts "     |     |     "
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}  "
    puts "     |     |     "
    puts "-----+-----+-----"
    puts "     |     |     "
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}  "
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
  include FormatIO

  attr_accessor :score
  attr_reader :name, :marker

  @@names = []
  @@markers = []
  @@m_idx = 0
  @@m_jdx = 1

  def initialize
    @score = 0
  end

  def marker=(mark)
    if mark.length != 1
      puts "Marker must be a single character. Try something else"
      self.marker = gets.chomp
    elsif taken?(mark)
      puts "Sorry, that marker is taken. Try something else"
      self.marker = gets.chomp
    else
      @marker = mark
      update_marker_info
    end
  end

  def update_marker_info
    @@markers[@@m_idx] = marker
    @@m_idx = (@@m_idx + 1) % 2
    @@m_jdx = (@@m_jdx + 1) % 2
  end

  def taken?(mark)
    @@m_idx == 1 && @@markers[@@m_jdx].to_s.downcase == mark.downcase
  end

  def name=(str)
    if str.empty?
      puts "You must enter a name."
      self.name = gets.chomp
    elsif @@names.include?(str)
      puts "Sorry, that name is taken. Please enter another name:"
      self.name = gets.chomp
    else
      @name = str
      @@names << str
    end
  end
end

class TTTGame
  include FormatIO
  include Loadable

  HUMAN_MARKER = "X"
  COMPUTER_MARKER = "O"
  FIRST_TO_MOVE_IDX = 0
  WIN_CONDITION = 5

  # rubocop:disable Metrics/MethodLength
  def play
    clear
    display_welcome_message
    settings_n_info
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
  # rubocop:enable Metrics/MethodLength

  private

  def settings_n_info
    set_names
    set_markers
    set_difficulty
    clear
  end

  def set_names
    puts "Enter your name:"
    human.name = gets.chomp
    puts "Enter a name for your opponent:"
    computer.name = gets.chomp
  end

  # rubocop:disable Metrics/MethodLength
  def set_markers
    puts "Would you like to set custom markers for the tournament? (y/n)"
    answer = nil
    loop do
      answer = gets.chomp.downcase
      break if answer == 'y' || answer == 'n'
      puts "Input must be 'y' or 'n'"
    end
    case answer
    when 'y'
      choose_markers
    when 'n'
      reset_default_markers
    end
  end
  # rubocop:enable Metrics/MethodLength

  def reset_default_markers
    human.marker = HUMAN_MARKER
    computer.marker = COMPUTER_MARKER
  end

  def choose_markers
    puts "Choose your marker"
    human.marker = gets.chomp
    puts "Choose #{computer.name}'s marker"
    computer.marker = gets.chomp
  end

  def prompt_for_difficulty
    puts ""
    puts "Please select a difficulty level for the tournament:\n"
    puts "Easy (e)\n"
    puts "Medium (m)\n"
    puts "Impossible(i)"
  end

  def set_difficulty
    prompt_for_difficulty

    move_methods[1] = case difficulty
                       when 'e'
                         Proc.new { easy_moves }
                       when 'm'
                         Proc.new { medium_moves }
                       when 'i'
                         Proc.new { unbeatable_moves }
                       end
  end

  def difficulty
    result = nil
    loop do
      result = gets.chomp.downcase
      break if result == 'e' || result == 'm' || result == 'i'
      puts "Input must be 'e', 'm', or 'i'\n"
    end
    result
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
      puts "#{computer.name} won the tournament!"
    end
    puts ''
    print_final_score
    puts ''
  end

  def print_final_score
    puts 'FINAL SCORE'
    puts "#{human.name}: #{human.score} #{computer.name}: #{computer.score}"
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
      run_game
      if tournament_over?
        self.tournament_won = true
        break
      end
      break unless play_again?
      ready_play_again
    end
  end

  def ready_play_again
    alternate_starting_player
    reset
    display_play_again_message
  end

  def run_game
    display_board
    player_moves
    clear_screen_and_display_board
    display_result
  end

  def alternate_starting_player
    self.starting_player_idx = (starting_player_idx + 1) % 2
  end

  def player_moves
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  attr_reader :board, :human, :computer, :smart_move
  attr_accessor :tournament_won, :starting_player_idx, :turn_idx, :move_methods

  def initialize
    @board = Board.new
    @human = Player.new
    @computer = Player.new
    @tournament_won = false
    ready_moves
  end

  def ready_moves
    @move_methods = [Proc.new { human_moves }]
    @turn_idx = FIRST_TO_MOVE_IDX
    @starting_player_idx = FIRST_TO_MOVE_IDX
    @smart_move = Proc.new do
      choices, _score = minimax(computer, board, human)
      choice = sneak_attack(choices)
      board[choice] = computer.marker
    end
  end

  def display_welcome_message
    puts ""
    puts "Welcome to Tic Tac Toe!"
    puts "First player to win #{WIN_CONDITION} rounds wins the tournament!"
    puts ""
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  # rubocop:disable Metrics/AbcSize
  def display_board
    puts ""
    puts "You're a #{human.marker}. #{computer.name} is a #{computer.marker}"
    puts "Your score: #{human.score}. " \
    "#{computer.name}'s score: #{computer.score}"
    puts ""
    board.draw
    puts ""
  end
  # rubocop:enable Metrics/AbcSize

  # def joinor(arr, delim=',', last='or')
  #   case arr.size
  #   when 1
  #     arr[0]
  #   when 2
  #     arr.join(" #{last} ")
  #   else
  #     "#{arr[0..-2].join("#{delim} ")}#{delim} #{last} #{arr[-1]}"
  #   end
  # end

  # rubocop:disable Metrics/MethodLength
  def display_available_spots
    string = ''
    i = 7
    j = 1
    line = ''
    loop do
      line << if board.unmarked_keys.include?(i)
                i.to_s
              else
                '_'
              end

      if (i % 3).zero?
        line = line.center(FormatIO::LINE_LENGTH)
        line << "\n"
        string << line
        line = ''
        i -= 5
      else
        line << ' '
        i += 1
      end
      j += 1
      break if j == 10
    end
    print string
  end
  # rubocop:enable Metrics/MethodLength

  def cheat_display
    clear_screen_and_display_board
    puts "Choose a square"
    string = ''
    i = 7
    j = 1
    line = ''
    loop do
      line << if board.unmarked_keys.include?(i)
                i.to_s
              else
                '_'
              end

      if (i % 3).zero?
        line = line.center(FormatIO::LINE_LENGTH)
        line << "\n"
        string << line
        line = ''
        i -= 5
      else
        line << ' '
        i += 1
      end
      j += 1
      break if j == 10
    end

    a = Proc.new do
      if first_move?
        good_choices = (1..9).to_a
      else
        good_choices, score = minimax(human, board, computer)
      end

      if score == 10
        good_choices = immediate_wins_for(computer)
      end

      string = string.chars.map do |chr|
        if good_choices.include?(chr.to_i)
          chr.red
        else
          chr
        end
      end.join
    end

    load(a)
    print string
  end

  def human_moves
    puts "Choose a square"
    puts "(Confused? Enter 'help' for guidance)"
    display_available_spots
    puts ''
    square = choose_valid_spot
    board[square] = human.marker
  end

  # rubocop:disable Metrics/MethodLength
  def choose_valid_spot
    square = nil
    helped = false
    loop do
      answer = gets.chomp
      if answer == "help" && !helped
        cheat_display
        helped = true
        answer = gets.chomp
      end
      begin
        square = Integer(answer)
      rescue ArgumentError
        square = nil
      end
      break if board.unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice."
    end
    square
  end
  # rubocop:enable Metrics/MethodLength

  def easy_moves
    board[board.unmarked_keys.sample] = computer.marker
  end

  def medium_moves
    winning_spots = immediate_wins_for(computer)
    defensive_moves = immediate_wins_for(human)
    choice = if !winning_spots.empty?
               winning_spots.sample
             elsif !defensive_moves.empty?
               defensive_moves.sample
             else
               board.unmarked_keys.sample
             end
    board[choice] = computer.marker
  end

  def immediate_wins_for(player)
    winning_spots = []
    Board::WINNING_LINES.each do |line|
      winning_spot = spot_wins(line, player)
      winning_spots << winning_spot if winning_spot
    end
    winning_spots
  end

  # rubocop:disable Metrics/MethodLength
  def spot_wins(line, player)
    count = 0
    choice = nil
    line.each do |key|
      if board.squares[key].marker == player.marker
        count += 1
      else
        choice = key
      end
    end

    return choice if count == 2 && board.unmarked_keys.include?(choice)
    nil
  end
  # rubocop:enable Metrics/MethodLength

  def first_move?
    board.unmarked_keys.size == 9
  end

  def unbeatable_moves
    winning_spots = immediate_wins_for(computer)
    if !winning_spots.empty?
      board[winning_spots.sample] = computer.marker
    elsif first_move?
      board[board.unmarked_keys.sample] = computer.marker
    else
      load(smart_move)
    end
  end

  def get_score(player, brd)
    case brd.winning_marker
    when player.marker
      -10
    when nil
      0
    else
      10
    end
  end

  def scores_for_unmarked_spots(player, brd, opponent)
    available_keys = []
    scores = []
    brd.unmarked_keys.each do |key|
      available_keys << key
      bord = brd.dup
      bord[key] = player.marker
      _, b = minimax(opponent, bord, player)
      scores << b
    end
    return available_keys, scores
  end

  # rubocop:disable Metrics/MethodLength
  def perfect_choices(scores)
    options = []
    best = -10
    scores.each_with_index do |e, i|
      if e > best
        options = [i]
        best = e
      elsif e == best
        options << i
      end
    end
    options
  end
  # rubocop:enable Metrics/MethodLength

  def reverse_for_lower_stack_frame(score)
    case score
    when 10
      -10
    when -10
      10
    else
      0
    end
  end

  def minimax(player, brd, opponent)
    return nil, get_score(player, brd) if brd.someone_won? || brd.full?

    available_keys, scores = scores_for_unmarked_spots(player, brd, opponent)

    choices = perfect_choices(scores)
    points = reverse_for_lower_stack_frame(scores[choices.sample])
    moves = choices.map { |choice| available_keys[choice] }
    return moves, points
  end

  def sneak_attack(moves)
    return moves[0] if moves.size == 1

    if moves.any? { |move| non_forcing?(move) }
      moves.select { |move| non_forcing?(move) }.sample
    else
      moves.sample
    end
  end

  def non_forcing?(move)
    brd = board.dup
    brd[move] = computer.marker
    choices, _score = minimax(human, brd, computer)
    choices.size > 1
  end

  def display_result
    case board.winning_marker
    when human.marker
      puts 'You won!'
      human.score += 1
    when computer.marker
      puts "#{computer.name} won!"
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
    self.turn_idx = starting_player_idx
    clear
  end

  def display_play_again_message
    puts ""
    puts "Let's play again!"
    puts ""
  end

  def current_player_moves
    move_methods[turn_idx].call
    switch_current_method
  end

  def switch_current_method
    self.turn_idx = (turn_idx + 1) % 2
  end

  def human_turn?
    turn_idx == 0
  end
end

game = TTTGame.new
game.play
