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

  # run `each` with progress
  # ==== Example
  #   [1, 2, 3].each_with_progress('Numbers') do |number|
  #     # code
  #   end
  def each_with_progress(title = nil, &block)
    with_progress(title).each(&block)
  end

  # run `each_with_index` with progress
  # ==== Example
  #   [1, 2, 3].each_with_index_and_progress('Numbers') do |number, index|
  #     # code
  #   end
  def each_with_index_and_progress(title = nil, &block)
    with_progress(title).each_with_index(&block)
  end
end
