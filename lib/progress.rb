require 'singleton'

class Progress
  include Singleton

  # start progress indication
  # ==== Examples
  #   Progress.start('Test', 1000)
  #   ...
  #   Progress.step
  #   ...
  #   Progress.stop('Test', 1000)
  #
  #   Progress.start('Test', 1000) do
  #     ...
  #     Progress.step
  #     ...
  #   end
  def self.start(name, total = 100)
    levels << new(name, total, levels.length)
    print_message
    if block_given?
      yield
      stop
    end
  end

  def self.step
    levels[-1].step
    print_message
  end

  def self.stop
    levels.pop.stop
    print_message unless levels.empty?
  end

  # :nodoc:
  def self.io=(io)
    @io = io
  end

  # :nodoc:
  def initialize(name, total, level)
    @name = name + ': %s'
    @total = total
    @level = level
    @current = 0
    start
  end

  # :nodoc:
  def start
    self.message = '...'
  end

  # :nodoc:
  def step
    @current += 1
    self.message = percent
  end

  # :nodoc:
  def stop
    self.message = percent
  end

  # :nodoc:
  def message
    @message
  end

protected

  def self.print_message
    message = levels.map{ |level| level.message } * ' > '
    @io ||= $stdout
    @io.sync = true
    @io.print "\r" + message.ljust(@previous_length || 0).gsub(/\d+\.\d+/){ |s| s == '100.0' ? s : "\e[1m#{s}\e[0m" }
    @previous_length = message.length
  end

  def self.levels
    @levels ||= []
  end

  def percent
    '%5.1f%%' % (@current * 100.0 / @total)
  end

  def message=(s)
    formatted = s.ljust(6)[0, 6]
    @message = @name % formatted
  end
end

require 'enumerable'
require 'integer'
