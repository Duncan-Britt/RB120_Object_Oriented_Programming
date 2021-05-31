class GuessingGame
  GUESS_MAX = 7

  def play
    loop do
      puts ''
      puts "You have #{GUESS_MAX - guess_cnt} guesses remaining."
      guess = input_guess
      self.guess_cnt += 1
      case guess <=> number
      when -1
        puts "Your guess is too low."
      when 0
        puts "That's the number!"
        display_won
        return
      when 1
        puts "You're guess is too high."
      end
      break if guess_cnt == GUESS_MAX
    end
    puts ''
    puts 'You hvae no more guesses. You lost!'
  end

  private

  attr_reader :number
  attr_accessor :guess_cnt

  def display_won
    puts ''
    puts 'You won!'
  end

  def input_guess
    loop do
      print "Enter a number between 1 and 100: "
      begin
        guess = Integer(gets.chomp)
        return guess if guess <= 100 && guess >= 1
      rescue ArgumentError
      end
      print "Invalid guess. "
    end
  end

  def initialize
    @number = rand(100) + 1
    @guess_cnt = 0
  end
end

game = GuessingGame.new
game.play

=begin
You have 7 guesses remaining.
Enter a number between 1 and 100: 104
Invalid guess. Enter a number between 1 and 100: 50
Your guess is too low.

You have 6 guesses remaining.
Enter a number between 1 and 100: 75
Your guess is too low.

You have 5 guesses remaining.
Enter a number between 1 and 100: 85
Your guess is too high.

You have 4 guesses remaining.
Enter a number between 1 and 100: 0
Invalid guess. Enter a number between 1 and 100: 80

You have 3 guesses remaining.
Enter a number between 1 and 100: 81
That's the number!

You won!

game.play

You have 7 guesses remaining.
Enter a number between 1 and 100: 50
Your guess is too high.

You have 6 guesses remaining.
Enter a number between 1 and 100: 25
Your guess is too low.

You have 5 guesses remaining.
Enter a number between 1 and 100: 37
Your guess is too high.

You have 4 guesses remaining.
Enter a number between 1 and 100: 31
Your guess is too low.

You have 3 guesses remaining.
Enter a number between 1 and 100: 34
Your guess is too high.

You have 2 guesses remaining.
Enter a number between 1 and 100: 32
Your guess is too low.

You have 1 guesses remaining.
Enter a number between 1 and 100: 32
Your guess is too low.

You have no more guesses. You lost!
=end
