module Enumerable
  # note that Progress.step is called automatically
  # ==== Example
  #   [1, 2, 3].each_with_progress('Numbers') do |number|
  #     sleep(number)
  #   end
  def each_with_progress(name, options = {})
    Progress.start(name, length, options) do
      each do |item|
        yield item
        Progress.step
      end
    end
  end

  # note that Progress.step is called automatically
  # ==== Example
  #   [1, 2, 3].each_with_index_and_progress('Numbers') do |number, index|
  #     sleep(number)
  #   end
  def each_with_index_and_progress(name, options = {})
    Progress.start(name, length, options) do
      each_with_index do |item, index|
        yield item, index
        Progress.step
      end
    end
  end
end
