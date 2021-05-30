module IOable
  INDENT = 5
  def output(str)
    puts ' ' * INDENT + str
  end

  def output_l(str)
    print ' ' * INDENT + str
  end

  def input
    print ' '
    gets.chomp
  end
end

class Participant
  FACE = {
    jack: 10,
    queen: 10,
    king: 10,
    ace: 10
  }

  attr_reader :hand, :deck

  def initialize(deck)
    @deck = deck
    @hand = []
  end

  def hit
    hand << deck.deal
  end

  def busted?
    total > 21
  end

  def total
    not_aces = hand.reject { |card| card.face == :ace }
    ace_count = hand.size - not_aces.size
    non_ace_total = not_aces.reduce(0) do |acc, card|
      if card.face.instance_of?(Integer)
        acc + card.face
      else
        acc + FACE[card.face]
      end
    end
    if non_ace_total + 11 + ace_count - 1 <= 21
      if ace_count == 0
        non_ace_total
      else
        non_ace_total + ace_count - 1 + 11
      end
    else
      non_ace_total + ace_count
    end
  end
end

class Deck
  attr_reader :cards

  def initialize
    @cards = initialize_deck
  end

  def initialize_deck
    deck = []
    faces = [2, 3, 4, 5, 6, 7, 8, 9, 10, :jack, :queen, :king, :ace]
    suits = [:hearts, :diamonds, :clubs, :spades]
    suits.each do |suit|
      faces.each do |face|
        deck << Card.new(face, suit)
      end
    end
    deck
  end

  def deal
    cards.delete_at(rand(cards.size))
  end
end

class Card
  attr_reader :face, :suit

  def initialize(face, suit)
    @face = face
    @suit = suit
  end

  def to_s
    # "#{face} of #{suit}"
    face.to_s
  end

  def inspect
    to_s
  end
end

class Game
  include IOable

  attr_reader :player, :dealer, :deck

  def initialize
    @deck = Deck.new
    @player = Participant.new(@deck)
    @dealer = Participant.new(@deck)
  end

  def start
    deal_cards
    show_cards
    player_turn
    if player.busted?
      display_player_bust
    else
      dealer_turn
      if dealer.busted?
        display_dealer_bust
      else
        show_result
      end
    end
    Game.new.start if play_again?
  end

  private

  def play_again?
    output ''
    output_l "Press enter to play again, or enter 'Q' to quit."
    case input.upcase
    when 'Q'
      system 'clear'
      output ''
      output 'Thank you for playing Twenty-One. Goodbye!'
      output ''
      false
    else
      true
    end
  end

  def deal_cards
    2.times do
      player.hand << deck.deal
      dealer.hand << deck.deal
    end
  end

  def show_final_cards
    system 'clear'
    output "\n\n"
    output "Dealer has: #{join_and(dealer.hand)}    (#{dealer.total})"
    output "You have: #{join_and(player.hand)}    (#{player.total})"
  end

  def show_cards
    system 'clear'
    output "\n\n"
    output "Dealer has: #{dealer.hand.first.to_s.capitalize} and ?"
    output "You have: #{join_and(player.hand)}    (#{player.total})"
  end

  def show_result
    show_final_cards
    output ''
    case player.total <=> dealer.total
    when 1
      output "You won! " \
      "Your score: #{player.total}, dealer score: #{dealer.total}"
    when 0
      output "Tie!"
    when -1
      output "Dealer won! " \
      "Player score: #{player.total}, dealer score: #{dealer.total}"
    end
  end

  def player_turn
    output ''
    output_l "Hit or stay? (h/s)"

    case input.downcase
    when 'h'
      player.hit
      return if player.busted?
      show_cards
      player_turn
    when 's'
      return
    else
      output 'Invalid input.'
      player_turn
    end
  end

  def dealer_turn
    until dealer.total >= 17
      if dealer.busted?
        return
      end
      dealer.hit
    end
  end

  def display_dealer_bust
    show_cards
    output ''
    output 'Dealer busted. You win!'
  end

  def display_player_bust
    show_cards
    output ''
    output 'You busted. Dealer wins!'
  end

  def join_and(arr)
    if arr.size >= 3
      str = ''
      i = 0
      until i == arr.size - 1
        str << "#{arr[i].to_s.capitalize}, "
        i += 1
      end
      str << "and #{arr[i].to_s.capitalize}"
    elsif arr.size == 2
      str = arr[0].to_s
      str << " and #{arr[1].to_s.capitalize}"
    else
      arr[0].to_s
    end
  end
end

Game.new.start
