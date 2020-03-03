require 'aws-sdk-iam'

module Stax
  module Aws
    class Iam < Sdk

      class << self

        def client
          @_client ||= ::Aws::IAM::Client.new
        end

        def aliases
          client.list_account_aliases.account_aliases
        end

      end

    end
  end
end
