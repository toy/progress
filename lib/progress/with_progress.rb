require 'progress'

class Progress
  class WithProgress
    attr_reader :enumerable, :title

    # initialize with object responding to each, title and optional length
    # if block is provided, it is passed to each
    def initialize(enumerable, title, length = nil, &block)
      @enumerable, @title, @length = enumerable, title, length
      each(&block) if block
    end

    # returns self but changes title
    def with_progress(title = nil, length = nil, &block)
      self.class.new(@enumerable, title, length || @length, &block)
    end

    # befriend with in_threads gem
    def in_threads(*args, &block)
      @enumerable.in_threads(*args).with_progress(@title, @length, &block)
    rescue
      super
    end

    def respond_to?(sym, include_private = false)
      enumerable_method?(method) || super(sym, include_private)
    end

    def method_missing(method, *args, &block)
      if enumerable_method?(method)
        run(method, *args, &block)
      else
        super(method, *args, &block)
      end
    end

  protected

    def enumerable_method?(method)
      method == :each || Enumerable.method_defined?(method)
    end

    def run(method, *args, &block)
      enumerable = case
      when @length
        @enumerable
      when
            @enumerable.is_a?(String),
            @enumerable.is_a?(IO),
            Object.const_defined?(:StringIO) && @enumerable.is_a?(StringIO),
            Object.const_defined?(:TempFile) && @enumerable.is_a?(TempFile)
        warn "Progress: collecting elements for instance of class #{@enumerable.class}"
        lines = []
        @enumerable.each{ |line| lines << line }
        lines
      else
        @enumerable
      end

      length = case
      when @length
        @length
      when enumerable.respond_to?(:size)
        enumerable.size
      when enumerable.respond_to?(:length)
        enumerable.length
      else
        enumerable.count
      end

      if block
        result = Progress.start(@title, length) do
          enumerable.send(method, *args) do |*block_args|
            Progress.step do
              block.call(*block_args)
            end
          end
        end
        if result.eql?(enumerable)
          @enumerable
        else
          result
        end
      else
        Progress.start(@title) do
          Progress.step do
            enumerable.send(method, *args)
          end
        end
      end
    end

  end
end
