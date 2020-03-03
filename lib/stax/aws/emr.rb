require 'aws-sdk-emr'

module Stax
  module Aws
    class Emr < Sdk

      class << self

        def client
          @_client ||= ::Aws::EMR::Client.new
        end

        def describe(id)
          client.describe_cluster(cluster_id: id).cluster
        end

        def groups(id)
          ## TODO paginate me
          client.list_instance_groups(cluster_id: id).instance_groups
        end

        def instances(id, types = nil)
          ## TODO paginate me
          client.list_instances(cluster_id: id, instance_group_types: types).instances
        end

      end
    end
  end
end
