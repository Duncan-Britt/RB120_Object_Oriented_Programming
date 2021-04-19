# POLYMORPHISM BY INHERITANCE

class Animal
  def eat
    # generic eat method
  end
end

class Fish < Animal
  def eat
    # eating specific to fish
  end
end

class Cat < Animal
  def eat
     # eat implementation for cat
  end
end

def feed_animal(animal)
  animal.eat
end

array_of_animals = [Animal.new, Fish.new, Cat.new]
array_of_animals.each do |animal|
  feed_animal(animal)
end

# POLYMORPHISM THROUGH DUCK TYPING

class Wedding
  attr_reader :guests, :flowers, :songs

  def prepare(preparers)
    preparers.each do |preparer|
      preparer.prepare_wedding(self)
    end
  end
end

class Chef
  def prepare_wedding(wedding)
    prepare_food(wedding.guests)
  end

  def prepare_food(guests)
    #implementation
  end
end

class Decorator
  def prepare_wedding(wedding)
    decorate_place(wedding.flowers)
  end

  def decorate_place(flowers)
    # implementation
  end
end

class Musician
  def prepare_wedding(wedding)
    prepare_performance(wedding.songs)
  end

  def prepare_performance(songs)
    #implementation
  end
end

=begin
      ENCAPSULATION lets us hide the internal representation of an object and
      only expose the methods and properties that users of the object need. We
      can use method access control to expose these properties and methods through the public (or external) interface of the class: its public methods
=end
