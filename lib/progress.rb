# encoding: UTF-8

require 'singleton'
require 'thread'

# ==== Procedural example
#   Progress.start('Test', 1000)
#   1000.times do
#     Progress.step do
#       # do something
#     end
#   end
#   Progress.stop
# ==== Block example
#   Progress.start('Test', 1000) do
#     1000.times do
#       Progress.step do
#         # do something
#       end
#     end
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
class Progress
  include Singleton

  attr_reader :total
  attr_reader :current
  attr_reader :title
  attr_accessor :note
  def initialize(total, title)
    if !total.kind_of?(Numeric) && (title.nil? || title.kind_of?(Numeric))
      total, title = title, total
    end
    total = total && total != 0 ? Float(total) : 1.0

    @total = total
    @current = 0.0
    @title = title
  end

  def to_f(inner)
    inner = 1.0 if inner > 1.0
    inner *= @step if @step
    (current + inner) / total
  end

  def step(step, note)
    if !step.kind_of?(Numeric)
      step, note = nil, step
    end
    step = 1 if step.nil?

    @step = step
    @note = note
    ret = yield if block_given?
    Thread.exclusive do
      @current += step
    end
    ret
  end

  def set(new_current, note)
    @step = new_current - @current
    @note = note
    ret = yield if block_given?
    Thread.exclusive do
      @current = new_current
    end
    ret
  end

  @lock = Mutex.new
  class << self

    # start progress indication
    def start(total = nil, title = nil)
      lock do
        if running?
          unless @started_in == Thread.current
            warn 'Can\'t start inner progress in different thread'
            if block_given?
              return yield
            else
              return
            end
          end
        else
          @started_in = Thread.current
          @eta = Eta.new
          start_beeper
        end
        @levels ||= []
        @levels.push new(total, title)
      end
      print_message :force => true
      if block_given?
        begin
          yield
        ensure
          stop
        end
      end
    end

    # step current progress
    def step(step = nil, note = nil, &block)
      if running?
        ret = @levels.last.step(step, note, &block)
        print_message
        ret
      elsif block
        block.call
      end
    end

    # set value of current progress
    def set(new_current, note = nil, &block)
      if running?
        ret = @levels.last.set(new_current, note, &block)
        print_message
        ret
      elsif block
        block.call
      end
    end

    # stop progress
    def stop
      if running?
        if @levels.length == 1
          print_message :force => true, :finish => true
          stop_beeper
        end
        @levels.pop
      end
    end

    # check if progress was started
    def running?
      @levels && !@levels.empty?
    end

    # set note
    def note=(note)
      if running?
        @levels.last.note = note
      end
    end

    # stay on one line
    def stay_on_line?
      @stay_on_line.nil? ? io_tty? : @stay_on_line
    end

    # explicitly set staying on one line [true/false/nil]
    def stay_on_line=(value)
      @stay_on_line = true && value
    end

    # highlight output using control characters
    def highlight?
      @highlight.nil? ? io_tty? : @highlight
    end

    # explicitly set highlighting [true/false/nil]
    def highlight=(value)
      @highlight = true && value
    end

    # show progerss in terminal title
    def set_terminal_title?
      @set_terminal_title.nil? ? io_tty? : @set_terminal_title
    end

    # explicitly set showing progress in terminal title [true/false/nil]
    def set_terminal_title=(value)
      @set_terminal_title = true && value
    end

  private

    def lock(force = true)
      if force ? @lock.lock : @lock.try_lock
        begin
          yield
        ensure
          @lock.unlock
        end
      end
    end

    def io
      @io || $stderr
    end

    def io_tty?
      io.tty? || ENV['PROGRESS_TTY']
    end

    def start_beeper
      @beeper = Beeper.new(10) do
        print_message
      end
    end

    def stop_beeper
      @beeper.stop if @beeper
    end

    def restart_beeper
      @beeper.restart if @beeper
    end

    def time_to_print?
      !@next_time_to_print || @next_time_to_print <= Time.now
    end

    def eta(current)
      @eta.left(current)
    end

    def elapsed
      @eta.elapsed
    end

    def print_message(options = {})
      force = options[:force]
      lock force do
        if force || time_to_print?
          @next_time_to_print = Time.now + 0.3
          restart_beeper

          current = 0
          parts = []
          title_parts = []
          @levels.reverse.each do |level|
            current = level.to_f(current)

            percent = current == 0 ? '......' : "#{'%5.1f' % (current * 100.0)}%"
            title = level.title && "#{level.title}: "
            if !highlight? || percent == '100.0%'
              parts << "#{title}#{percent}"
            else
              parts << "#{title}\e[1m#{percent}\e[0m"
            end
            title_parts << "#{title}#{percent}"
          end

          timing = if options[:finish]
            " (elapsed: #{elapsed})"
          elsif eta_ = eta(current)
            " (ETA: #{eta_})"
          end

          message = "#{parts.reverse * ' > '}#{timing}"
          text_message = "#{title_parts.reverse * ' > '}#{timing}"

          if note = running? && @levels.last.note
            message << " - #{note}"
            text_message << " - #{note}"
          end

          message = "\r#{message}\e[K" if stay_on_line?
          message << "\n" if !stay_on_line? || options[:finish]
          io << message

          if set_terminal_title?
            title = options[:finish] ? nil : text_message.to_s.gsub("\a", '␇')
            io << "\e]0;#{title}\a"
          end
        end
      end
    end

  end
end

require 'progress/beeper'
require 'progress/eta'

require 'progress/enumerable'
require 'progress/integer'
require 'progress/active_record' if defined?(ActiveRecord::Base)

module Kernel
  def Progress(*args, &block)
    Progress.start(*args, &block)
  end
  private :Progress
end
