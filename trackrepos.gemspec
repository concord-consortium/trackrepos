# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'trackrepos/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Stephen Bannasch"]
  gem.email         = ["sbannasch@concord.org"]
  gem.description   = %q{Uses yaml configuration files to track and update collections of external git repositories}
  gem.summary       = %q{Useful for tracking large numbers of external git repositories}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "trackrepos"
  gem.require_paths = ["lib"]
  gem.version       = TrackRepos::VERSION
end
