class Progress
  class Eta
    def initialize
      @started_at = Time.now
    end

    def left(completed)
      seconds = seconds_left(completed)
      if seconds && seconds > 0
        seconds_to_string(seconds)
      end
    end

    def elapsed
      seconds_to_string(Time.now - @started_at)
    end

  private

    def seconds_to_string(seconds)
      if seconds
        case seconds
        when 0...60
          '%.0fs' % seconds
        when 60...3600
          '%.1fm' % (seconds / 60)
        when 3600...86400
          '%.1fh' % (seconds / 3600)
        else
          '%.1fd' % (seconds / 86400)
        end
      end
    end

    def seconds_left(completed)
      now = Time.now
      if completed > 0 && now - @started_at >= 1
        current_eta = @started_at + (now - @started_at) / completed
        @left = if @left
          @left + (current_eta - @left) * (1 + completed) * 0.5
        else
          current_eta
        end
        @left - now
      end
    end
  end
end
