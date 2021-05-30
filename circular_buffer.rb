class CircularQueue
  def enqueue(data)
    node = Node.new(data)
    self.head = node unless head

    if size == max_size
      self.head = head.succ
    else
      self.size += 1
    end

    self.tail.succ = node if tail
    self.tail = node
  end

  def dequeue
    return nil unless head
    result = self.head.data
    self.head = head.succ
    self.size -= 1
    result
  end

  private

  attr_reader :max_size
  attr_accessor :head, :tail, :size

  def initialize(max_size)
    @max_size = max_size
    @size = 0
    @head = nil
    @tail = nil
  end

  class Node
    attr_reader :data
    attr_accessor :succ

    def initialize(data)
      @data = data
    end
  end
end

queue = CircularQueue.new(3)
puts queue.dequeue == nil

queue.enqueue(1)
queue.enqueue(2)
puts queue.dequeue == 1

queue.enqueue(3)
queue.enqueue(4)
puts queue.dequeue == 2

queue.enqueue(5)
queue.enqueue(6)
queue.enqueue(7)
puts queue.dequeue == 5
puts queue.dequeue == 6
puts queue.dequeue == 7
puts queue.dequeue == nil

queue = CircularQueue.new(4)
puts queue.dequeue == nil

queue.enqueue(1)
queue.enqueue(2)
puts queue.dequeue == 1

queue.enqueue(3)
queue.enqueue(4)
puts queue.dequeue == 2

queue.enqueue(5)
queue.enqueue(6)
queue.enqueue(7)
puts queue.dequeue == 4
puts queue.dequeue == 5
puts queue.dequeue == 6
puts queue.dequeue == 7
puts queue.dequeue == nil
