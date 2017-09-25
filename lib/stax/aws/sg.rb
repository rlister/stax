module Stax
  module Aws
    class Sg < Sdk

      class << self

        def client
          @_client ||= ::Aws::EC2::Client.new
        end

        def describe(ids)
          client.describe_security_groups(group_ids: Array(ids)).security_groups
        end

      end
    end
  end
end