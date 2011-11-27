require 'enumerator'
require 'progress/with_progress'

module Enumerable
  # run any Enumerable method with progress
  # methods which don't necessarily go through all items (like find, any? or all?) will not show 100%
  # ==== Example
  #   [1, 2, 3].with_progress('Numbers').each do |number|
  #     # code
  #   end
  #   [1, 2, 3].with_progress('Numbers').each_cons(2) do |numbers|
  #     # code
  #   end
  def with_progress(title = nil)
    Progress::WithProgress.new(self, title)
  end
end
