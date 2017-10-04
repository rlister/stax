require 'stax/aws/s3'

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

        def stack_tagged_buckets
          Aws::S3.list_buckets.select do |bucket|
            region = Aws::S3.bucket_region(bucket.name)
            next unless region.empty? || region == ENV['AWS_REGION']
            tags = Aws::S3.bucket_tags(bucket.name)
            tags.any? { |t| t.key == 'aws:cloudformation:stack-name' && t.value == my.stack_name }
          end
        end
      end

      desc 'buckets', 'S3 buckets for this stack'
      def buckets
        puts stack_s3_buckets.map(&:physical_resource_id)
      end

      desc 'tagged', 'S3 buckets that were tagged by this stack'
      def tagged
        print_table stack_tagged_buckets.map { |b|
          [b.name, b.creation_date]
        }
      end

      # desc 'reap', 'S3 reaper for all buckets tagged by this stack'
      # def reap
      #   s3_buckets.map(&:name).each do |bucket|
      #     debug("Cleaning up #{bucket}")
      #     begin
      #       debug("Removing all objects in bucket #{bucket}")
      #       s3(:clean, [bucket], yes: true)
      #       sleep(3)
      #       debug("Deleting S3 bucket #{bucket}")
      #       if s3(:empty?, [bucket], quiet: true)
      #         s3(:remove_bucket, [bucket], yes: true)
      #       else
      #         warn("#{bucket} not empty: maybe re-run cleanup")
      #       end
      #     rescue Aws::S3::Errors::NoSuchBucket # allow a little idempotence
      #       debug("No bucket #{bucket}: skipping")
      #     end
      #   end
      # end

    end
  end
end