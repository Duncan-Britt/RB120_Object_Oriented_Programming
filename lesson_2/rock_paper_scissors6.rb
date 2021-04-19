module MyString
  def self.titleize(str)
    words = str.split
    words.map { |word| word.capitalize }.join(' ')
  end
end

class Move
  VALUES = ['rock', 'paper', 'scissors', 'lizard', 'spock']
  def initialize(value)
    @value = value
  end

  def scissors?
    @value == 'scissors'
  end

  def rock?
    @value == 'rock'
  end

  def paper?
    @value == 'paper'
  end

  def lizard?
    @value == 'lizard'
  end

  def spock?
    @value == 'spock'
  end

  def >(other_move)
    (rock? && (other_move.scissors? || other_move.lizard?)) ||
      (paper? && (other_move.rock? || other_move.spock?)) ||
      (scissors? && (other_move.paper? || other_move.lizard?)) ||
      (lizard? && (other_move.spock? || other_move.paper?)) ||
      (spock? && (other_move.scissors? || other_move.rock?))
  end

  def <(other_move)
    (rock? && (other_move.paper? || other_move.spock?)) ||
      (paper? && (other_move.scissors? || other_move.lizard?)) ||
      (scissors? && (other_move.rock? || other_move.spock?)) ||
      (lizard? && (other_move.scissors? || other_move.rock?)) ||
      (spock? && (other_move.paper? || other_move.lizard?))
  end

  def to_s
    @value
  end
end

class Player
  attr_accessor :move, :name, :score, :previous_moves

  def initialize
    set_name
    @score = 0
    @previous_moves = []
  end

  def previous
    previous_moves.join(', ')
  end
end

class Human < Player
  def set_name
    n = ""
    loop do
      puts "What's your name?"
      n = gets.chomp
      break unless n.empty?
      puts "Sorry, must enter a value."
    end
    self.name = n
  end

  def among_values
    arr = Move::VALUES
    str = arr[0..-2].join(', ')
    if arr.size > 2
      str + ", or " + arr[-1]
    else
      str + " or " + arr[-1]
    end
  end

  def choose
    choice = nil
    loop do
      puts "Please choose #{among_values}:"
      choice = gets.chomp
      break if Move::VALUES.include?(choice)
      puts "Sorry, invalid choice."
    end
    self.move = Move.new(choice)
    self.previous_moves << self.move
  end
end

class Computer < Player
  def set_name
    self.name = ['R2D2', 'Hal', 'Chappie', 'Sonny', 'Number 5'].sample
  end

  def choose
    self.move = Move.new(Move::VALUES.sample)
    self.previous_moves << self.move
  end
end

class RPSGame
  attr_accessor :human, :computer, :score, :winner, :tourn_winner

  def initialize
    @human = Human.new
    @computer = Computer.new
    @winner = nil
    @tourn_winner = nil
  end

  def game_name
    MyString.titleize(Move::VALUES.join(', '))
  end

  def display_welcome_message
    puts "Welcome to #{game_name}!"
  end

  def display_goodbye_message
    puts "Thanks for playing #{game_name}. Goodbye!"
  end

  def display_moves
    puts "#{human.name} chose #{human.move}"
    puts "#{computer.name} chose #{computer.move}"
  end

  def update_score
    return unless winner
    winner.score += 1
  end

  def update_winner
    if human.move > computer.move
      self.winner = human
    elsif human.move < computer.move
      self.winner = computer
    else
      self.winner = nil
    end
  end

  def display_winner
    if winner
      puts "#{winner.name} won!"
    else
      puts "It's a tie"
    end
  end

  def display_score
    printf "SCORE #{human.name}: #{human.score}" +
    " #{computer.name}: #{computer.score}\n"
  end

  def display_tournament
    puts "#{tourn_winner.name} won the tournament!"
    self.tourn_winner = nil
    human.score = 0
    computer.score = 0
    self.computer = Computer.new
  end

  def assess_score
    if human.score == 10
      self.tourn_winner = human
      display_tournament
    elsif computer.score == 10
      self.tourn_winner = computer
      display_tournament
    end
  end

  def play_again?
    answer = nil
    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp
      break if ['y', 'n'].include? answer.downcase
      puts "Sorry, must be y or n"
    end

    return true if answer.downcase == 'y'
    return false if answer.downcase == 'n'
  end

  def display_previous_moves
    unless human.previous_moves.empty?
      puts "#{human.name}'s previous moves: #{human.previous}"
      puts "#{computer.name}'s previous moves: #{computer.previous}"
    end
  end

  def play
    display_welcome_message
    loop do
      display_previous_moves
      human.choose
      computer.choose
      display_moves
      update_winner
      display_winner
      update_score
      display_score
      assess_score
      break unless play_again?
    end
    display_goodbye_message
  end
end

RPSGame.new.play
