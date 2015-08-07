# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'reorm/version'

Gem::Specification.new do |spec|
  spec.name          = "reorm"
  spec.version       = Reorm::VERSION
  spec.authors       = ["Peter Wood"]
  spec.email         = ["peter.wood@longboat.com"]
  spec.summary       = %q{A library for use with the RethinkDB application.}
  spec.description   = %q{A library the wraps RQL and provides a basic model class for the RethinkDB system.}
  spec.homepage      = "https://github.com/free-beer/reorm"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"

  spec.add_dependency "activesupport", "~> 4.2"
  spec.add_dependency "configurative", "~> 0.1"
  spec.add_dependency "connection_pool", "~> 2.2"
  spec.add_dependency "logjam", "~> 1.2"
  spec.add_dependency "rethinkdb", "~> 2.0"
end
