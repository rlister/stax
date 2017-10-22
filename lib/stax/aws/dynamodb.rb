module Stax
  module Aws
    class DynamoDB < Sdk

      class << self

        def client
          @_client ||= ::Aws::DynamoDB::Client.new
        end

        def table(name)
          client.describe_table(table_name: name).table
        end

      end

    end
  end
end