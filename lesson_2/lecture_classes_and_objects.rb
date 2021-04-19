class Person
  attr_accessor :first_name, :last_name

  def initialize(full_name)
    parse_full_name(full_name)
  end

  def name=(full_name)
    parse_full_name(full_name)
  end

  def name
    "#{first_name} #{last_name}".strip
  end

  def same_name?(person)
    self.name == person.name
  end

  def to_s
    name
  end

  private

  def parse_full_name(full_name)
    parts = full_name.split
    self.first_name = parts.first
    self.last_name = parts[1] ? parts.last : ''
  end
end

bob = Person.new("Robert Smith")
puts "The person's name is: #{bob}"
