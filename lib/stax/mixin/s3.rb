# require 'stax/aws/s3'

module Stax
  module S3
    def self.included(thor)
      thor.desc(:s3, 'S3 subcommands')
      thor.subcommand(:s3, Cmd::S3)
    end
  end

  module Cmd
    class S3 < SubCommand
      no_commands do
        def stack_s3_buckets
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::S3::Bucket')
        end
      end

      desc 'buckets', 'S3 buckets for this stack'
      def buckets
        puts stack_s3_buckets.map(&:physical_resource_id)
      end

      desc 'tagged', 'S3 buckets that were tagged by this stack'
      def tagged
        # TODO
      end

      desc 'reap', 'S3 reaper for all buckets tagged by this stack'
      def reap
        # TODO
      end

    end
  end
end