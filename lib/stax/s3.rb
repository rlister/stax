require 'awful/s3'

module Stax
  module S3
    def self.included(thor)
      thor.class_eval do

        no_commands do
          def s3_buckets
            s3(:tagged, [stack_name], stack: stack_name, quiet: true)
          end

          def s3_reap
            s3_buckets.map(&:name).each do |bucket|
              debug("Cleaning up #{bucket}")
              begin
                debug("Removing all objects in bucket #{bucket}")
                s3(:clean, [bucket], yes: true)
                sleep(3)
                debug("Deleting S3 bucket #{bucket}")
                if s3(:empty?, [bucket], quiet: true)
                  s3(:remove_bucket, [bucket], yes: true)
                else
                  warn("#{bucket} not empty: maybe re-run cleanup")
                end
              rescue Aws::S3::Errors::NoSuchBucket # allow a little idempotence
                debug("No bucket #{bucket}: skipping")
              end
            end
          end
        end

        desc 'buckets', 'list s3 buckets tagged for this stack'
        method_option :reap, type: :boolean, default: false, desc: 'reap all buckets tagged by this stack'
        def buckets
          debug("S3 buckets tagged by stack #{stack_name}")
          s3(:tagged, [stack_name], stack: stack_name)
          s3_reap if options[:reap]
        end

      end
    end
  end
end