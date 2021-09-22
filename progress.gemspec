# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = 'progress'
  s.version     = '3.6.0'
  s.summary     = %q{Show progress of long running tasks}
  s.homepage    = "https://github.com/toy/#{s.name}"
  s.authors     = ['Ivan Kuchin']
  s.license     = 'MIT'

  s.required_ruby_version = '>= 1.9.3'

  s.metadata = {
    'bug_tracker_uri'   => "https://github.com/toy/#{s.name}/issues",
    'changelog_uri'     => "https://github.com/toy/#{s.name}/blob/master/CHANGELOG.markdown",
    'documentation_uri' => "https://www.rubydoc.info/gems/#{s.name}/#{s.version}",
    'source_code_uri'   => "https://github.com/toy/#{s.name}",
  }

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w[lib]

  s.add_development_dependency 'rspec', '~> 3.0'
  if RUBY_VERSION >= '2.4'
    s.add_development_dependency 'rubocop', '~> 1.0'
    s.add_development_dependency 'rubocop-rspec', '~> 2.0'
  end
end
