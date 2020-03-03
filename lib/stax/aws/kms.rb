require 'aws-sdk-kms'

module Stax
  module Aws
    class Kms < Sdk

      class << self

        def client
          @_client ||= ::Aws::KMS::Client.new
        end

        def describe(id)
          client.describe_key(key_id: id).key_metadata
        end

      end

    end
  end
end
