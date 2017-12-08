module Stax
  module Aws
    class Firehose < Sdk

      class << self

        def client
          @_client ||= ::Aws::Firehose::Client.new
        end

        def describe(name)
          client.describe_delivery_stream(delivery_stream_name: name).delivery_stream_description
        end

      end

    end
  end
end