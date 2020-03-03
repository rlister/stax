require 'aws-sdk-databasemigrationservice'

module Stax
  module Aws
    class Dms < Sdk

      class << self

        def client
          @_client ||= ::Aws::DatabaseMigrationService::Client.new
        end

        def endpoints(opt)
          client.describe_endpoints(opt).map(&:endpoints).flatten
        end

        def instances(opt)
          client.describe_replication_instances(opt).map(&:replication_instances).flatten
        end

        def tasks(opt)
          client.describe_replication_tasks(opt).map(&:replication_tasks).flatten
        end

        def test(opt)
          client.test_connection(opt).connection
        end

        def connections(opt)
          client.describe_connections(opt).map(&:connections).flatten
        end

        def start(opt)
          client.start_replication_task(opt).replication_task
        end

      end

    end
  end
end
