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
        rescue ::Aws::S3::Errors::NoSuchTagSet
          []
        end

        def bucket_region(bucket)
          client.get_bucket_location(bucket: bucket).location_constraint
        end

      end

    end
  end
end