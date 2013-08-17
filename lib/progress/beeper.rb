class Progress
  class Beeper
    class Restart < RuntimeError; end

    def initialize(time, &block)
      @thread = Thread.new do
        begin
          sleep time
          block.call
        rescue Restart
        end
        redo
      end
    end

    def restart
      @thread.raise Restart
    end

    def stop
      @thread.kill
    end
  end
end
