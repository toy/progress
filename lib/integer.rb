class Integer
  def times_with_progress(name)
    Progress.start(name, self) do
      times do |i|
        yield i
        Progress.step
      end
    end
  end
end
