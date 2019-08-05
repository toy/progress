# frozen_string_literal: true

require 'progress'

# Add Progress method as alias to Progress.start
module Kernel
private

  define_method :Progress do |*args, &block|
    Progress.start(*args, &block)
  end
end
