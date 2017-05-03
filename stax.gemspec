# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stax/version'

Gem::Specification.new do |spec|
  spec.name          = 'stax'
  spec.version       = Stax::VERSION
  spec.authors       = ['Richard Lister']
  spec.email         = ['rlister@gmail.com']

  spec.summary       = %q{Control Cloudformation stack and other stuff.}
  spec.description   = %q{Stax is a flexible set of ruby classes for wrangling your cloudformation stacks.}
  spec.homepage      = 'https://github.com/rlister/stax'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"

  # spec.add_dependency('aws-sdk', '>= 2.7.9')
  spec.add_dependency('awful', '>= 0.0.174')
  spec.add_dependency('thor')
  spec.add_dependency('cfer', '0.5.0')
  spec.add_dependency('octokit')
end