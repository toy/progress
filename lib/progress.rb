class Progress
  def self.start(name, total = 100)
    @io ||= $stdout
    @io.sync = true
    
    @each = total / 1000
    @count = 0

    @current = 0
    @total = total
    @name = name + ': %s'
    message highight('...')
    yield
    message percent
    @io.puts
  end

  def self.step
    @current += 1
    if (@count += 1) >= @each
      message highight(percent)
      @count = 0
    end
  end

private

  def self.percent
    '%5.1f%%' % (@current * 100.0 / @total)
  end
  
  def self.message(s)
    @io.print "\r\e[0K#{@name % s}"
  end

  def self.highight(s)
    "\e[1m#{s}\e[0m"
  end
end

require 'enumerable'
require 'integer'
