module Stax
  module Aws
    class Sqs < Sdk

      class << self

        def client
          @_client ||= ::Aws::SQS::Client.new
        end

        def get(url, attributes = :All)
          client.get_queue_attributes(queue_url: url, attribute_names: Array(attributes)).attributes
        end

        def purge(url)
          client.purge_queue(queue_url: url)
        end
      end

    end
  end
end