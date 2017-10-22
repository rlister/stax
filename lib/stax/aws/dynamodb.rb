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

        def gsi(name)
          client.describe_table(table_name: name).table.global_secondary_indexes || []
        end

        def lsi(name)
          client.describe_table(table_name: name).table.local_secondary_indexes || []
        end

      end

    end
  end
end