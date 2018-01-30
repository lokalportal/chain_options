
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chain_options/version'

Gem::Specification.new do |spec|
  spec.name          = 'chain_options'
  spec.version       = ChainOptions::VERSION
  spec.authors       = ['Stefan Exner']
  spec.email         = ['stex@sterex.de']

  spec.summary       = 'DSL to add non(destructive).option(methods).to(objects)'
  spec.homepage      = 'https://github.com/lokalportal/chain_options'
  spec.license       = 'MIT'
  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
