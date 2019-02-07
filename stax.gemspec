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

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "docile", "1.2.0"
  spec.add_development_dependency "stax-examples"

  spec.add_dependency('aws-sdk', '~> 2')
  spec.add_dependency('thor')
  spec.add_dependency('cfer')
  spec.add_dependency('octokit')
  spec.add_dependency('git_clone_url')
end