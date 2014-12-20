# encoding: UTF-8

class Progress
  # Class methods of Progress
  module ClassMethods
    def self.extended(klass)
      klass.instance_variable_set(:@lock, Mutex.new)
    end

    # start progress indication
    def start(total = nil, title = nil)
      init(total, title)
      print_message :force => true
      return unless block_given?
      begin
        yield
      ensure
        stop
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
      return unless running?
      if @levels.length == 1
        print_message :force => true, :finish => true
        stop_beeper
      end
      @levels.pop
    end

    # check if progress was started
    def running?
      @levels && !@levels.empty?
    end

    # set note
    def note=(note)
      return unless running?
      @levels.last.note = note
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
    def terminal_title?
      @terminal_title.nil? ? io_tty? : @terminal_title
    end

    # explicitly set showing progress in terminal title [true/false/nil]
    def terminal_title=(value)
      @terminal_title = true && value
    end

  private

    attr_reader :eta

    def init(total = nil, title = nil)
      lock do
        if running?
          unless @started_in == Thread.current
            warn 'Can\'t start inner progress in different thread'
            return block_given? ? yield : nil
          end
        else
          @started_in = Thread.current
          @eta = Eta.new
          start_beeper
        end
        @levels ||= []
        @levels.push new(total, title)
      end
    end

    def lock(force = true)
      if force
        @lock.lock
      else
        return unless @lock.try_lock
      end

      begin
        yield
      ensure
        @lock.unlock
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

            percent = if current.zero?
              '......'
            else
              format('%5.1f%%', current * 100.0)
            end
            title = level.title && "#{level.title}: "
            if !highlight? || percent == '100.0%'
              parts << "#{title}#{percent}"
            else
              parts << "#{title}\e[1m#{percent}\e[0m"
            end
            title_parts << "#{title}#{percent}"
          end

          timing = if options[:finish]
            " (elapsed: #{eta.elapsed})"
          elsif (left = eta.left(current))
            " (ETA: #{left})"
          end

          message = "#{parts.reverse * ' > '}#{timing}"
          text_message = "#{title_parts.reverse * ' > '}#{timing}"

          if running? && (note = @levels.last.note)
            message << " - #{note}"
            text_message << " - #{note}"
          end

          message = "\r#{message}\e[K" if stay_on_line?
          message << "\n" if !stay_on_line? || options[:finish]
          io << message

          if terminal_title?
            title = options[:finish] ? nil : text_message.to_s.gsub("\a", '␇')
            io << "\e]0;#{title}\a"
          end
        end
      end
    end
  end
end
