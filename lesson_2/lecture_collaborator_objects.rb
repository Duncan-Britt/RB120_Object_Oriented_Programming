=begin
      Objects that are stored as state within another object are called
      COLLABORATOR OBJECTS.

      When we work with collaborator objects, they are usually custom objects
      (e.g. defined by the programmer and not inherited from the Ruby core
      library). Yet, collaborator objects aren't strictly custom objects. Even
      a string object stored in an instance variable of an object is technially
      a collaborator object.


=end

class Person
  attr_accessor :name, :pets

  def initialize(name)
    @name = name
    @pets = []
  end
end

bob = Person.new("Robert")

kitty = Cat.new
bud = Bulldog.new

bob.pets << kitty
bob.pets << bud

bob.pets     # => [#<Cat:0x007fd839999620>, #<Bulldog:0x007fd839994ff8>]
