require 'pry'

class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red; colorize(31) end
end

module IOable
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

  def user_input(caps: false)
    if caps
      gets.chomp.upcase
    else
      gets.chomp
    end
  end

  def formatted(line)
    line = line.center(LINE_LENGTH)
    line << "\n"
  end

  def clear
    system 'clear'
  end

  def invalid(clr: true, msg: 'Invalid input')
    clear if clr
    puts ""
    puts msg, red: true
    method = caller[0][/`.*'/][1..-2].to_sym
    send(method)
  end
end

module Interfaceable
  STANDARD_INTERFACE = {
    play: 'P',
    settings: 'S',
    exit: 'E',
    no: 'N',
    yes: 'Y',
    interface: 'I',
    difficulty: 'D',
    markers: 'M',
    names: 'N',
    help: 'HELP',
    reset: 'R',
    easy: 'E',
    medium: 'M',
    imposs: 'I',
    home: 'H',
    standard: 'S',
    num_pad: 'N',
    top_left: 1,
    top: 2,
    top_right: 3,
    left: 4,
    middle: 5,
    right: 6,
    bottom_left: 7,
    bottom: 8,
    bottom_right: 9,
    next_row: 1
  }

  NUM_PAD_INTERFACE = {
    play: '1',
    settings: '2',
    exit: '3',
    no: '0',
    yes: '1',
    interface: '2',
    difficulty: '1',
    markers: '3',
    names: '4',
    help: '+',
    reset: '5',
    easy: '1',
    medium: '2',
    imposs: '3',
    home: '0',
    standard: '1',
    num_pad: '2',
    top_left: 7,
    top: 8,
    top_right: 9,
    left: 4,
    middle: 5,
    right: 6,
    bottom_left: 1,
    bottom: 2,
    bottom_right: 3,
    next_row: -5
  }
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
             ' ' * IOable::CURSOR_SPACE,
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

  include IOable

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
  # rubocop:disable Layout/LineLength
  def draw(interface)
    puts "     |     |     "
    puts "  #{@squares[interface[:top_left]]}  |  #{@squares[interface[:top]]}  |  #{@squares[interface[:top_right]]}  "
    puts "     |     |     "
    puts "-----+-----+-----"
    puts "     |     |     "
    puts "  #{@squares[interface[:left]]}  |  #{@squares[interface[:middle]]}  |  #{@squares[interface[:right]]}  "
    puts "     |     |     "
    puts "-----+-----+-----"
    puts "     |     |     "
    puts "  #{@squares[interface[:bottom_left]]}  |  #{@squares[interface[:bottom]]}  |  #{@squares[interface[:bottom_right]]}  "
    puts "     |     |     "
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Layout/LineLength

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
  include IOable

  attr_accessor :score
  attr_reader :name, :marker

  @@names = []
  @@markers = []
  @@m_idx = 0
  @@m_jdx = 1
  @@n_idx = 0
  @@n_jdx = 1

  def initialize(marker)
    @score = 0
    self.marker = marker
  end

  def marker=(mark)
    if mark.length != 1
      puts "Marker must be a single character. Try something else"
      self.marker = user_input
    elsif taken?(mark)
      puts "Sorry, that marker is taken. Try something else"
      self.marker = user_input
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

  def name_taken?(nom)
    @@n_idx == 1 && @@names[@@n_jdx].to_s.downcase == nom.downcase
  end

  def update_name_info
    @@names[@@n_idx] = name
    @@n_idx = (@@n_idx + 1) % 2
    @@n_jdx = (@@n_jdx + 1) % 2
  end

  def name=(str)
    if str.empty?
      puts "You must enter a name."
      self.name = user_input
    elsif name_taken?(str)
      puts "Sorry, that name is taken. Please enter another name:"
      self.name = user_input
    else
      @name = str
      update_name_info
    end
  end
end

class TTTGame
  include IOable
  include Interfaceable
  include Loadable

  HUMAN_MARKER = "X"
  COMPUTER_MARKER = "O"
  FIRST_TO_MOVE_IDX = 0
  WIN_CONDITION = 5
  COMPUTER_NAME = "TTT NET"

  def start
    clear
    display_welcome_message
    home_navigation
  end

  private

  attr_reader :board, :human, :computer, :smart_move
  attr_accessor :interface, :starting_player_idx,
                :turn_idx, :move_methods, :helper

  def initialize
    @interface = STANDARD_INTERFACE
    @board = Board.new
    @human = Player.new(HUMAN_MARKER)
    @computer = Player.new(COMPUTER_MARKER)
    @helper = false
    ready_moves
    default_names
  end

  def default_names
    clear
    puts "\n"
    puts "Please enter your name"
    computer.name = COMPUTER_NAME
    human.name = user_input
  end

  def ready_moves
    @default_ai_move = Proc.new { medium_moves }
    @move_methods = [Proc.new { human_moves }, @default_ai_move]
    @turn_idx = FIRST_TO_MOVE_IDX
    @starting_player_idx = FIRST_TO_MOVE_IDX
    @smart_move = Proc.new do
      choices, _score = minimax(computer, board, human)
      choice = sneak_attack(choices)
      board[choice] = computer.marker
    end
  end

  def display_welcome_message
    puts "\n"
    puts "Welcome to Tic Tac Toe!"
  end

  def clear_and_home_navigation
    clear
    home_navigation
  end

  def home_navigation
    home_display

    case user_input(caps: true)
    when interface[:play] then start_tournament
    when interface[:settings] then clear_and_settings_menu
    when interface[:exit] then clear_and_exit_game
    else
      invalid
    end
  end

  def home_display
    puts "\n"
    puts "Play round (#{interface[:play]})"
    puts "Settings Menu (#{interface[:settings]})"
    puts "Exit (#{interface[:exit]})"
  end

  def clear_and_settings_menu
    clear
    settings_menu
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  def settings_menu
    display_settings

    case user_input(caps: true)
    when interface[:home] then clear_and_home_navigation
    when interface[:difficulty] then clear_and_set_difficulty
    when interface[:interface] then clear_and_set_interface
    when interface[:markers] then set_markers
    when interface[:names] then set_names
    when interface[:help] then toggle_helper_and_settings_menu
    when interface[:reset]
      if default_settings?
        invalid
      else
        reset_default_settings
      end
    else
      invalid
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def display_settings
    puts "\n"
    puts "Enter '#{interface[:home]}' to return to home screen"
    puts ''
    puts 'SETTINGS'
    puts ''

    puts "Difficulty (#{interface[:difficulty]})"
    puts "Interface (#{interface[:interface]})"
    puts "Markers (#{interface[:markers]})"
    puts "Player Names (#{interface[:names]})"
    puts "#{enable_disable_str} Helper Tool (#{interface[:help]})"
    return if default_settings?
    puts "Reset Default Settings " \
    "(#{interface[:reset]})"
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def enable_disable_str
    if helper_enabled?
      'Disable'
    else
      'Enable'
    end
  end

  def helper_enabled?
    @helper
  end

  def toggle_helper
    self.helper = !helper
  end

  def toggle_helper_and_settings_menu
    toggle_helper
    clear_and_settings_menu
  end

  def reset_default_settings
    reset_default_difficulty
    self.interface = STANDARD_INTERFACE
    reset_default_markers
    computer.name = COMPUTER_NAME unless computer.name == COMPUTER_NAME
    toggle_helper if helper_enabled?
    clear_and_settings_menu
  end

  def default_settings?
    move_methods[1] == @default_ai_move &&
      interface == STANDARD_INTERFACE &&
      human.marker == HUMAN_MARKER &&
      computer.marker == COMPUTER_MARKER &&
      computer.name == COMPUTER_NAME &&
      !helper_enabled?
  end

  def reset_default_difficulty
    move_methods[1] = @default_ai_move
  end

  def clear_and_set_interface
    clear
    set_interface
    clear_and_settings_menu
  end

  def set_interface
    puts "\n"
    puts "Standard Interface (#{interface[:standard]})"
    puts "Num Pad Interface (#{interface[:num_pad]})"
    case user_input(caps: true)
    when interface[:standard] then self.interface = STANDARD_INTERFACE
    when interface[:num_pad] then self.interface = NUM_PAD_INTERFACE
    else
      invalid
    end
  end

  def reset_default_markers
    human.marker = HUMAN_MARKER
    computer.marker = COMPUTER_MARKER
  end

  def set_markers
    clear
    puts "\n"
    puts "Choose your marker"
    human.marker = user_input
    puts "Choose #{computer.name}'s marker"
    computer.marker = user_input
    clear_and_settings_menu
  end

  def set_names
    clear
    puts "\n"
    puts "Enter a name for your opponent"
    computer.name = user_input
    puts "What's your name?"
    human.name = user_input
    clear_and_settings_menu
  end

  def clear_and_set_difficulty
    clear
    set_difficulty
    clear_and_settings_menu
  end

  def set_difficulty
    prompt_for_difficulty

    move_methods[1] = case user_input(caps: true)
                      when interface[:easy] then Proc.new { easy_moves }
                      when interface[:medium] then @default_ai_move
                      when interface[:imposs] then Proc.new { unbeatable_moves }
                      else
                        invalid
                      end
  end

  def prompt_for_difficulty
    puts "\n"
    puts "Please select a difficulty level for the tournament:\n"
    puts "Easy (#{interface[:easy]})\n"
    puts "Medium (#{interface[:medium]})\n"
    puts "Impossible(#{interface[:imposs]})"
  end

  def clear_and_exit_game
    clear
    exit_game
  end

  def exit_game
    puts "\n"
    puts "Are you sure you want to exit the game? " \
    "(#{interface[:yes]}/#{interface[:no]})"
    case user_input(caps: true)
    when interface[:no] then clear_and_home_navigation
    when interface[:yes] then display_goodbye_message
    else
      invalid
    end
  end

  def display_goodbye_message
    clear
    puts "\n"
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
    puts "\n"
  end

  def start_tournament
    reset_tournament
    puts "\n"
    puts "First player to win #{WIN_CONDITION} rounds wins the tournament!"
    run_tournament
  end

  def reset_tournament
    self.starting_player_idx = FIRST_TO_MOVE_IDX
    self.turn_idx = starting_player_idx
    board.reset
    human.score = 0
    computer.score = 0
    clear
  end

  def run_tournament
    run_game
    if tournament_over?
      display_tournament_result
      home_navigation
    elsif play_again?
      reset_game
      run_tournament
    else
      clear_and_home_navigation
    end
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

  def reset_game
    board.reset
    alternate_starting_player
    clear
  end

  def alternate_starting_player
    self.starting_player_idx = (starting_player_idx + 1) % 2
    self.turn_idx = starting_player_idx
  end

  def play_again?
    puts "Would you like to play again? (#{interface[:yes]}/#{interface[:no]})"
    yes_or_no?
  end

  def yes_or_no?
    case user_input(caps: true)
    when interface[:yes] then true
    when interface[:no] then false
    else
      invalid(
        clr: false,
        msg: "Sorry, must be #{interface[:yes]} or #{interface[:no]}"
      )
    end
  end

  def run_game
    display_board
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
    clear_screen_and_display_board
    display_result
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def tournament_over?
    human.score == WIN_CONDITION || computer.score == WIN_CONDITION
  end

  # rubocop:disable Metrics/AbcSize
  def display_board
    puts "\n"
    puts "You're a #{human.marker}. #{computer.name} is a #{computer.marker}"
    puts "Your score: #{human.score}. " \
    "#{computer.name}'s score: #{computer.score}"
    puts ""
    board.draw(interface)
    puts ""
  end
  # rubocop:enable Metrics/AbcSize

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

  def human_moves
    puts "Choose a square"
    if helper_enabled?
      puts "(Confused? Enter '#{interface[:help]}' for guidance)"
    end
    display_available_spots
    puts ''
    square = choose_valid_spot
    board[square] = human.marker
  end

  # rubocop:disable Metrics/MethodLength
  def choose_valid_spot
    square = nil
    helped_already = false
    loop do
      answer = user_input(caps: true)
      if answer == interface[:help] && !helped_already && helper_enabled?
        cheat_display
        helped_already = true
        answer = user_input
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

  def display_available_spots
    string = available_grid
    print string
  end

  # rubocop:disable Metrics/MethodLength
  def available_grid
    grid = ''
    line = ''
    count = 1
    square_idx = interface[:top_left]
    loop do
      line << square_unless_taken(square_idx)
      line, grid, square_idx = update_grid_lines(line.dup, grid.dup, square_idx)
      count += 1
      break if count == 10
    end
    grid
  end
  # rubocop:enable Metrics/MethodLength

  def update_grid_lines(line, grid, square_idx)
    if end_of_line?(square_idx)
      grid << formatted(line)
      line = ''
      square_idx += interface[:next_row]
    else
      line << ' '
      square_idx += 1
    end
    return line, grid, square_idx
  end

  def square_unless_taken(square_idx)
    if board.unmarked_keys.include?(square_idx)
      square_idx.to_s
    else
      '_'
    end
  end

  def end_of_line?(square_idx)
    (square_idx % 3).zero?
  end

  def cheat_display
    clear_screen_and_display_board
    puts "Choose a square"
    highlights = nil
    load(-> { highlights = good_choices })
    print highlight(available_grid, highlights)
  end

  def good_choices
    if first_move?
      good_choices = (1..9).to_a
    else
      good_choices, score = minimax(human, board, computer)
    end
    return good_choices unless score == 10
    immediate_wins_for(computer)
  end

  def highlight(grid, highlights)
    grid.chars.map do |chr|
      if highlights.include?(chr.to_i)
        chr.red
      else
        chr
      end
    end.join
  end

  def easy_moves
    board[random_spot] = computer.marker
  end

  def medium_moves
    winning_spots = immediate_wins_for(computer)
    defensive_moves = immediate_wins_for(human)
    choice = if !winning_spots.empty?
               winning_spots.sample
             elsif !defensive_moves.empty?
               defensive_moves.sample
             else
               random_spot
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
      board[random_spot] = computer.marker
    else
      load(smart_move)
    end
  end

  def random_spot
    board.unmarked_keys.sample
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
    when 10 then -10
    when -10 then 10
    when 0 then 0
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
end

game = TTTGame.new
game.start
