require 'aws-sdk-s3'

module Stax
  module Aws
    class S3 < Sdk

      class << self

        def client
          @_client ||= ::Aws::S3::Client.new
        end

        def list_buckets
          client.list_buckets.buckets
        end

        def bucket_tags(bucket)
          client.get_bucket_tagging(bucket: bucket).tag_set
        rescue ::Aws::Errors::NoSuchEndpointError
          warn("socket error for #{bucket}, retrying")
          sleep 1
          retry
        rescue ::Aws::S3::Errors::NoSuchTagSet
          []
        end

        def bucket_region(bucket)
          client.get_bucket_location(bucket: bucket).location_constraint
        end

        ## get region, return us-east-1 if empty
        def location(bucket)
          l = client.get_bucket_location(bucket: bucket).location_constraint
          l.empty? ? 'us-east-1' : l
        end

        def put(opt)
          client.put_object(opt)
        end

        def get_lifecycle(bucket)
          client.get_bucket_lifecycle_configuration(bucket: bucket).rules
        end

        def put_lifecycle(bucket, cfg)
          client.put_bucket_lifecycle_configuration(bucket: bucket, lifecycle_configuration: cfg)
        end

      end

    end
  end
end
