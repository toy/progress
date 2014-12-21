require 'progress'

class Progress
  # Handling with_progress
  class WithProgress
    attr_reader :enum, :title
    alias_method :enumerable, :enum

    # If block given run each on instance otherwise return instance
    def self.new(*args, &block)
      block ? super.each(&block) : super
    end

    # initialize with object responding to each, title and optional length
    # if block is provided, it is passed to each
    def initialize(enum, title, length = nil)
      @enum, @title, @length = enum, title, length
    end

    # returns self but changes title
    def with_progress(title = nil, length = nil, &block)
      self.class.new(@enum, title, length || @length, &block)
    end

    # befriend with in_threads gem
    def in_threads(*args, &block)
      @enum.in_threads(*args).with_progress(@title, @length, &block)
    rescue
      super
    end

    def respond_to?(method, include_private = false)
      enumerable_method?(method) || super
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
      enum, length = resolve_enum_n_length

      if block
        result = Progress.start(@title, length) do
          enum.send(method, *args) do |*block_args|
            Progress.step do
              block.call(*block_args)
            end
          end
        end
        result.eql?(enum) ? @enum : result
      else
        Progress.start(@title) do
          Progress.step do
            enum.send(method, *args)
          end
        end
      end
    end

    def resolve_enum_n_length
      return [@enum, @length] if @length
      enum = enum_for_progress(@enum)
      [enum, enum_length(enum)]
    end

    def enum_for_progress(enum)
      case
      when
            enum.is_a?(String),
            enum.is_a?(IO),
            defined?(StringIO) && enum.is_a?(StringIO),
            defined?(Tempfile) && enum.is_a?(Tempfile)
        warn "Progress: collecting elements for #{enum.class} instance"
        lines = []
        enum.each{ |line| lines << line }
        lines
      else
        enum
      end
    end

    def enum_length(enum)
      return enum.size if enum.respond_to?(:size)
      return enum.length if enum.respond_to?(:length)
      enum.count
    end
  end
end
