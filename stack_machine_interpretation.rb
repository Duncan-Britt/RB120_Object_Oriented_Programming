class Minilang
  def eval
    instructions.each do |command|
      begin
        self.register = Integer(command)
      rescue ArgumentError
        case command
        when 'PRINT'
          puts register
        when 'PUSH'
          node = Node.new(register)
          node.pred = top if top
          self.top = node
        when 'POP'
          if top
            self.register = top.data
            self.top = top.pred
          else
            puts 'Emtpy stack!'
            return
          end
        when 'MULT'
          self.register = register * top.data
        when 'DIV'
          self.register = register / top.data
        when 'MOD'
          self.register = register % top.data
        when 'ADD'
          self.register = register + top.data
        when 'SUB'
          self.register = register - top.data
        else
          puts "Invalid token: #{command}"
          return
        end
      end
    end
  end

  private

  attr_reader :instructions
  attr_accessor :register, :top

  def initialize(instructions)
    @instructions = instructions.split
    @register = 0
    @top = nil
  end

  class Node
    attr_reader :data
    attr_accessor :pred

    def initialize(data)
      @data = data
    end
  end
end

Minilang.new('PRINT').eval
# 0

Minilang.new('5 PUSH 3 MULT PRINT').eval
# 15

Minilang.new('5 PRINT PUSH 3 PRINT ADD PRINT').eval
# 5
# 3
# 8

Minilang.new('5 PUSH 10 PRINT POP PRINT').eval
# 10
# 5

Minilang.new('5 PUSH POP POP PRINT').eval
# Empty stack!

Minilang.new('3 PUSH PUSH 7 DIV MULT PRINT ').eval
# 6

Minilang.new('4 PUSH PUSH 7 MOD MULT PRINT ').eval
# 12

Minilang.new('-3 PUSH 5 XSUB PRINT').eval
# Invalid token: XSUB

Minilang.new('-3 PUSH 5 SUB PRINT').eval
# 8

Minilang.new('6 PUSH').eval
# (nothing printed; no PRINT commands)
