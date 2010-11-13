require 'singleton'

class Progress
  include Singleton

  module InstanceMethods # :nodoc:
    attr_accessor :title, :current, :total
    attr_reader :current_step
    def initialize(title, total)
      if title.is_a?(Numeric) && total.nil?
        title, total = nil, title
      elsif total.nil?
        total = 1
      end
      @title = title
      @current = 0.0
      @total = total == 0.0 ? 1.0 : Float(total)
    end

    def step_if_blank
      if current == 0.0 && total == 1.0
        self.current = 1.0
      end
    end

    def to_f(inner)
      inner = [inner, 1.0].min
      if current_step
        inner *= current_step
      end
      (current + inner) / total
    end

    def step(steps)
      @current_step = steps
      yield
    ensure
      @current_step = nil
    end
  end
  include InstanceMethods

  class << self
    # start progress indication
    # ==== Procedural example
    #   Progress.start('Test', 1000)
    #   1000.times{ Progress.step }
    #   Progress.stop
    # ==== Block example
    #   Progress.start('Test', 1000) do
    #     1000.times{ Progress.step }
    #   end
    # ==== Step must not always be one
    #   symbols = []
    #   Progress.start('Input 100 symbols', 100) do
    #     while symbols.length < 100
    #       input = gets.scan(/\S/)
    #       symbols += input
    #       Progress.step input.length
    #     end
    #   end
    # ==== Enclosed block example
    #   [1, 2, 3].each_with_progress('1 2 3') do |one_of_1_2_3|
    #     10.times_with_progress('10') do |one_of_10|
    #       sleep(0.001)
    #     end
    #   end
    # ==== To output progress as lines (not trying to stay on line)
    #   Progress.lines = true
    # ==== To force highlight
    #   Progress.highlight = true
    def start(title = nil, total = nil)
      levels << new(title, total)
      print_message(true)
      if block_given?
        begin
          yield
        ensure
          stop
        end
      end
    end

    def step(steps = 1)
      if levels.last
        if block_given?
          levels.last.step(steps) do
            yield
          end
        end
        levels.last.current += Float(steps)
        print_message
      elsif block_given?
        yield
      end
    end

    def set(value)
      if levels.last
        levels.last.current = Float(value)
        print_message
      end
    end

    def stop
      if levels.last
        if levels.last.step_if_blank || levels.length == 1
          print_message(true)
        end
        levels.pop
        if levels.empty?
          io.puts
        end
      end
    end

    attr_writer :lines, :highlight # :nodoc:

  private

    def levels
      @levels ||= []
    end

    def io
      unless @io
        @io = $stderr
        @io.sync = true
      end
      @io
    end

    def io_tty?
      io.tty? || ENV['PROGRESS_TTY']
    end

    def lines?
      @lines.nil? ? !io_tty? : @lines
    end

    def highlight?
      @highlight.nil? ? io_tty? : @highlight
    end

    def time_to_print?
      if @previous
        if @previous < Time.now - 0.3
          @previous = Time.now
          true
        else
          false
        end
      else
        @previous = Time.now
        true
      end
    end

    def print_message(force = false)
      if force || time_to_print?
        messages = []
        inner = 0
        levels.reverse.each do |l|
          current = l.to_f(inner)
          value = current == 0 ? '......' : "#{'%5.1f' % (current * 100.0)}%"
          message = ''
          if l.title
            message << "#{l.title}: "
          end
          if !highlight? || value == '100.0%'
            message << value
          else
            message << "\e[1m#{value}\e[0m"
          end
          messages << message
          inner = current
        end
        message = messages.reverse * ' > '

        unless lines?
          previous_length = @previous_length || 0
          message_cl = if highlight?
            message.gsub(/\033\[(0|1)m/, '')
          else
            message
          end
          @previous_length = message_cl.length
          message = "#{message}#{' ' * [previous_length - message_cl.length, 0].max}\r"
        end

        lines? ? io.puts(message) : io.print(message)
      end
    end
  end
end

require 'progress/enumerable'
require 'progress/integer'
require 'progress/kernel'
require 'progress/active_record'
