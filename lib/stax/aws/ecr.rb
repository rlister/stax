require 'base64'

module Stax
  module Aws
    class Ecr < Sdk

      class << self

        def client
          @_client ||= ::Aws::ECR::Client.new
        end

        def auth
          client.get_authorization_token.authorization_data
        end

      end

    end
  end
end