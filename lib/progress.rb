class Progress
  def self.start(name, total = 100)
    $stdout.sync = true
    
    # @mutex ||= Mutex.new
    
    @each = total / 1000
    @count = 0

    @current = 0
    @total = total
    @name = name + ': %s'
    message highight('...')
    yield
    message percent
    puts
  end

  def self.step
    # @mutex.synchronize do
      @current += 1
      if (@count += 1) >= @each
        message highight(percent)
        @count = 0
      end
    # end
  end

private

  def self.percent
    '%5.1f%%' % (@current * 100.0 / @total)
  end
  
  def self.message(s)
    print "\r\e[0K#{@name % s}"
  end

  def self.highight(s)
    "\e[1m#{s}\e[0m"
  end
end

require 'array'
require 'integer'
