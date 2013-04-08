# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'runivedo/version'

Gem::Specification.new do |gem|
  gem.name          = "runivedo"
  gem.version       = Runivedo::VERSION
  gem.authors       = ["Lucas Clemente"]
  gem.email         = ["lucas@univedo.com"]
  gem.summary       = %q{Ruby binding for Univedo}
  gem.description   = %q{Ruby binding for Univedo}
  gem.homepage      = "https://univedo.com/"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency("faye-websocket")
  gem.add_dependency("active_support")
  gem.add_dependency("eventmachine")
  gem.add_dependency("term-ansicolor")
  gem.add_dependency("readline-history-restore")
  gem.add_dependency("terminal-table")
  gem.add_development_dependency('rspec')
  gem.add_development_dependency('rspec_junit_formatter')
  gem.add_development_dependency('fuubar')
end
