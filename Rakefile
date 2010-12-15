require 'rake'
require 'jeweler'
require 'rake/gem_ghost_task'
require 'spec/rake/spectask'

name = 'progress'

Jeweler::Tasks.new do |gem|
  gem.name = name
  gem.summary = %Q{Show progress of long running tasks}
  gem.homepage = "http://github.com/toy/#{name}"
  gem.license = 'MIT'
  gem.authors = ['Ivan Kuchin']
  gem.add_development_dependency 'jeweler', '~> 1.5.1'
  gem.add_development_dependency 'rake-gem-ghost'
  gem.add_development_dependency 'rspec'
end
Jeweler::RubygemsDotOrgTasks.new
Rake::GemGhostTask.new

Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_opts = ['--colour --format progress --loadby mtime --reverse']
  spec.spec_files = FileList['spec/**/*_spec.rb']
end
task :default => :spec
