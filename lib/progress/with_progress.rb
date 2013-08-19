require 'progress'
require 'delegate'

class Progress
  class WithProgress < Delegator
    include Enumerable

    attr_reader :enumerable, :title

    # initialize with object responding to each, title and optional length
    # if block is provided, it is passed to each
    def initialize(enumerable, title, length = nil, &block)
      super(enumerable)
      @enumerable, @title, @length = enumerable, title, length
      each(&block) if block
    end

    # each object with progress
    def each
      enumerable = case
      when @length
        @enumerable
      when
            @enumerable.is_a?(String),
            @enumerable.is_a?(IO),
            Object.const_defined?(:StringIO) && @enumerable.is_a?(StringIO),
            Object.const_defined?(:TempFile) && @enumerable.is_a?(TempFile)
        warn "Progress: collecting elements for instance of class #{@enumerable.class}"
        @enumerable.each.to_a
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

  protected

    def __getobj__
      @enumerable
    end

    def __setobj__(obj)
      @enumerable = obj
    end

  end
end
