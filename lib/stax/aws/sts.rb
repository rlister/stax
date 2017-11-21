module Stax
  module Aws
    class Sts < Sdk

      class << self

        def client
          @_client ||= ::Aws::STS::Client.new
        end

        def id
          @_id ||= client.get_caller_identity
        end

        def account_id
          id.account
        end

        def user_id
          id.user_id
        end

        def user_arn
          id.arn
        end

      end

    end
  end
end