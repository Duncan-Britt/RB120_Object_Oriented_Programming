class Pet
  def run
    'running!'
  end

  def jump
    'jumping!'
  end
end

class Dog < Pet
  def speak
    'bark!'
  end

  def fetch
    'fetching!'
  end

  def swim
    'swimming!'
  end
end

class Cat < Pet
  def speak
    'meow!'
  end
end

class Bulldog < Dog
  def swim
    "can't swim!"
  end
end

pete = Pet.new
kitty = Cat.new
dave = Dog.new
bud = Bulldog.new

p pete.run                # => "running!"
# pete.speak              # => NoMethodError

p kitty.run               # => "running!"
p kitty.speak             # => "meow!"
# kitty.fetch             # => NoMethodError

p dave.speak              # => "bark!"

p bud.run                 # => "running!"
p bud.swim                # => "can't swim!"
p Bulldog.ancestors
