# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'runivedo/version'

Gem::Specification.new do |spec|
  spec.name          = "runivedo"
  spec.version       = Runivedo::VERSION
  spec.authors       = ["Lucas Clemente"]
  spec.email         = ["lucas@univedo.com"]
  spec.summary       = %q{Ruby binding for Univedo}
  spec.description   = %q{Ruby binding for Univedo, see https://github.com/univedo/runivedo for more information.}
  spec.homepage      = "https://github.com/univedo/runivedo"
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rfc-ws-client", '~> 1.2'
  spec.add_dependency "term-ansicolor"
  spec.add_dependency "readline-history-restore"
  spec.add_dependency "terminal-table"
  spec.add_dependency "uuidtools"
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'emoji-rspec'
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
