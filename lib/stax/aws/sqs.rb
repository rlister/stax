require 'aws-sdk-sqs'

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

        def queue_url(name)
          client.get_queue_url(queue_name: name)&.queue_url
        end

        def send(opt)
          client.send_message(opt)
        end
      end

    end
  end
end
