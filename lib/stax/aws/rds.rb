module Stax
  module Aws
    class Rds < Sdk

      class << self

        def client
          @_client ||= ::Aws::RDS::Client.new
        end

        def instances(opt)
          client.describe_db_instances(opt).map(&:db_instances).flatten
        end

      end

    end
  end
end