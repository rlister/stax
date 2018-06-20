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

        def stack_s3_bucket_names
          stack_s3_buckets.map(&:physical_resource_id)
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
        puts stack_s3_bucket_names
      end

      desc 'tagged', 'S3 buckets that were tagged by this stack'
      def tagged
        debug("Buckets tagged by stack #{my.stack_name}")
        print_table stack_tagged_buckets.map { |b|
          [b.name, b.creation_date]
        }
      end

      desc 'lifecycle', 'show/set lifecycle for tagged buckets'
      def lifecycle
        debug("Lifecycle for buckets tagged by #{my.stack_name}")
        stack_tagged_buckets.each do |bucket|
          Aws::S3.get_lifecycle(bucket.name).each do |l|
            puts YAML.dump(stringify_keys(l.to_hash))
          end
        end
      end

      desc 'expire', 'expire objects in tagged buckets'
      def expire(days = 1)
        debug("Expiring objects in buckets tagged by #{my.stack_name}")
        stack_tagged_buckets.each do |bucket|
          if yes?("Expire all objects for #{bucket.name} in #{days}d?", :yellow)
            Aws::S3.put_lifecycle(
              bucket.name,
              rules: [
                {
                  prefix: '',   # required, all objects
                  status: :Enabled,
                  expiration: {
                    days: days,
                  },
                  noncurrent_version_expiration: {
                    noncurrent_days: days,
                  },
                }
              ]
            )
          end
        end
      end

      desc 'clear', 'clear objects from buckets'
      method_option :names, aliases: '-n', type: :array, default: nil, desc: 'names of buckets to clear'
      def clear
        debug("Clearing buckets for #{my.stack_name}")
        (options[:names] || stack_s3_bucket_names).each do |b|
          if yes?("Clear contents of bucket #{b}?", :yellow)
            ::Aws::S3::Bucket.new(b).clear!
          end
        end
      end

      desc 'delete', 'delete buckets and objects'
      method_option :names, aliases: '-n', type: :array, default: nil, desc: 'names of buckets to delete'
      def delete
        debug("Deleting buckets for #{my.stack_name}")
        (options[:names] || stack_s3_bucket_names).each do |b|
          if yes?("Delete bucket and contents #{b}?", :yellow)
            ::Aws::S3::Bucket.new(b).delete!
          end
        end
      end

    end
  end
end