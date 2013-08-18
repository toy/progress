require 'progress'

class Progress
  class WithProgress
    include Enumerable

    attr_reader :enumerable, :title

    # initialize with object responding to each, title and optional length
    # if block is provided, it is passed to each
    def initialize(enumerable, title, length = nil, &block)
      @enumerable, @title, @length = enumerable, title, length
      each(&block) if block
    end

    # each object with progress
    def each
      enumerable = resolve_enumerable
      length = @length || enumerable.length

      Progress.start(@title, length) do
        enumerable.each do |object|
          Progress.step do
            yield object
          end
        end
        @enumerable
      end
    end

    # returns self but changes title
    def with_progress(title = nil, length = nil, &block)
      self.class.new(@enumerable, title, length || @length, &block)
    end

  private

    def resolve_enumerable
      case
      when @length
        @enumerable
      when
            !@enumerable.respond_to?(:length),
            @enumerable.is_a?(String),
            defined?(StringIO) && @enumerable.is_a?(StringIO),
            defined?(TempFile) && @enumerable.is_a?(TempFile)
        @enumerable.each.to_a
      else
        @enumerable
      end
    end
  end
end
