# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'icmp4em/version'

Gem::Specification.new do |gem|
  gem.name             = "icmp4em"
  gem.version          = ICMP4EM::VERSION
  gem.authors          = ["Norman Elton"]
  gem.email            = ["normelton@gmail.com"]
  gem.description      = %q{A high-performance ICMP engine build on EventMachine}
  gem.summary          = %q{A high-performance ICMP engine build on EventMachine}
  gem.homepage         = ""
  gem.extra_rdoc_files = ["README.rdoc"]

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'eventmachine', '>= 1.0.0'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'yard'
end
