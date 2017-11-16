module Stax
  module Aws
    class Sts < Sdk

      class << self

        def client
          @_client ||= ::Aws::STS::Client.new
        end

        def id
          client.get_caller_identity
        end

      end

    end
  end
end