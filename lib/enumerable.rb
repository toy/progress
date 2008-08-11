module Enumerable
  def each_with_progress(name)
    Progress.start(name, length) do
      each do |item|
        yield item
        Progress.step
      end
    end
  end
end
