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
      Progress.start(@title, length) do
        @enumerable.each do |object|
          Progress.step do
            yield object
          end
        end
      end
    end

    # determine number of objects
    def length
      @length ||= if @enumerable.respond_to?(:length) && !@enumerable.is_a?(String)
        @enumerable.length
      elsif @enumerable.respond_to?(:count)
        @enumerable.count
      elsif @enumerable.respond_to?(:to_a)
        @enumerable.to_a.length
      else
        @enumerable.inject(0){ |length, obj| length + 1 }
      end
    end

    # returns self but changes title
    def with_progress(title = nil, length = nil, &block)
      self.class.new(@enumerable, title, length || @length, &block)
    end
  end
end
