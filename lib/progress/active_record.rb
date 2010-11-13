if defined?(ActiveRecord::Batches::ClassMethods)
  module ActiveRecord::Batches::ClassMethods
    def find_each_with_progress(options = {})
      Progress.start(name.tableize, count(options)) do
        find_each do |model|
          yield model
          Progress.step
        end
      end
    end

    def find_in_batches_with_progress(options = {})
      Progress.start(name.tableize, count(options)) do
        find_in_batches do |batch|
          yield batch
          Progress.step batch.length
        end
      end
    end
  end
end
