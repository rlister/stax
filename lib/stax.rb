require 'stax/aws/sdk'
require 'stax/aws/cfn'

require 'stax/dsl'
require 'stax/staxfile'
require 'stax/base'
require 'stax/git'
require 'stax/cli'
require 'stax/subcommand'
require 'stax/cfer'

require 'stax/stack'
require 'stax/stack/cfn'
require 'stax/stack/crud'
require 'stax/stack/changeset'
require 'stax/stack/parameters'
require 'stax/stack/outputs'
require 'stax/stack/imports'
require 'stax/stack/resources'

require 'stax/mixin/ec2'
require 'stax/mixin/alb'
require 'stax/mixin/elb'
require 'stax/mixin/sg'
require 'stax/mixin/s3'
require 'stax/mixin/asg'
require 'stax/mixin/ecs'
require 'stax/mixin/ecr'
require 'stax/mixin/sqs'
require 'stax/mixin/kms'
require 'stax/mixin/ssm'
require 'stax/mixin/keypair'
require 'stax/mixin/emr'
require 'stax/mixin/ssh'
require 'stax/mixin/lambda'
require 'stax/mixin/dynamodb'
require 'stax/mixin/logs'
require 'stax/mixin/apigw'
require 'stax/mixin/firehose'
require 'stax/mixin/codebuild'
require 'stax/mixin/codepipeline'
require 'stax/mixin/rds'