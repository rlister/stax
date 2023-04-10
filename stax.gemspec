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
  spec.add_development_dependency "stax-examples"

  spec.add_dependency('aws-sdk-cloudformation')
  spec.add_dependency('thor')
  spec.add_dependency('cfer', '>= 1.0.0')
  spec.add_dependency('octokit')
  spec.add_dependency('git_clone_url')

  ## service mixins
  spec.add_dependency('aws-sdk-acm')
  spec.add_dependency('aws-sdk-apigateway')
  spec.add_dependency('aws-sdk-autoscaling')
  spec.add_dependency('aws-sdk-cloudfront')
  spec.add_dependency('aws-sdk-cloudwatchlogs')
  spec.add_dependency('aws-sdk-codebuild')
  spec.add_dependency('aws-sdk-codepipeline')
  spec.add_dependency('aws-sdk-databasemigrationservice')
  spec.add_dependency('aws-sdk-dynamodb')
  spec.add_dependency('aws-sdk-ec2')
  spec.add_dependency('aws-sdk-ecr')
  spec.add_dependency('aws-sdk-elasticloadbalancing')
  spec.add_dependency('aws-sdk-elasticloadbalancingv2')
  spec.add_dependency('aws-sdk-ecs')
  spec.add_dependency('aws-sdk-emr')
  spec.add_dependency('aws-sdk-firehose')
  spec.add_dependency('aws-sdk-iam')
  spec.add_dependency('aws-sdk-kms')
  spec.add_dependency('aws-sdk-lambda')
  spec.add_dependency('aws-sdk-rds')
  spec.add_dependency('aws-sdk-route53')
  spec.add_dependency('aws-sdk-s3')
  spec.add_dependency('aws-sdk-secretsmanager')
  spec.add_dependency('aws-sdk-sqs')
  spec.add_dependency('aws-sdk-ssm')
end
