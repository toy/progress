require 'progress'

class Progress
  class WithProgress
    include Enumerable

    def initialize(enumerable, title, length = nil, &block)
      @enumerable, @title, @length = enumerable, title, length
      each(&block) if block
    end

    def each
      Progress.start(@title, length) do
        @enumerable.each do |object|
          Progress.step do
            yield object
          end
        end
      end
    end

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

    def with_progress(title = nil)
      self
    end
  end
end
