# frozen_string_literal: true

require 'progress'

# Add Progress method as alias to Progress.start
module Kernel
private

  def Progress(*args, &block) # rubocop:disable Naming/MethodName
    Progress.start(*args, &block)
  end
end
