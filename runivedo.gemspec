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
  spec.homepage      = "https://github.com/univedo/runivedo"
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rfc-ws-client", '~> 1.2'
  spec.add_dependency "cbor-simple", "~> 1.2.0"
  spec.add_dependency "uuidtools", "~> 2.1"
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-emoji'
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
