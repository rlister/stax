require 'aws-sdk-autoscaling'

module Stax
  module Aws
    class Asg < Sdk

      class << self

        def client
          @_client ||= ::Aws::AutoScaling::Client.new
        end

        def describe(names)
          paginate(:auto_scaling_groups) do |token|
            client.describe_auto_scaling_groups(auto_scaling_group_names: Array(names), next_token: token)
          end
        end

        def instances(names)
          ids = describe(names).map(&:instances).flatten.map(&:instance_id)
          return [] if ids.empty? # below call will return all instances in a/c if this empty
          paginate(:auto_scaling_instances) do |token|
            client.describe_auto_scaling_instances(instance_ids: ids, next_token: token)
          end
        end

        def update(name, opt = {})
          client.update_auto_scaling_group(opt.merge(auto_scaling_group_name: name))
        end

        def terminate(id, decrement = false)
          client.terminate_instance_in_auto_scaling_group(instance_id: id, should_decrement_desired_capacity: decrement)
        end
      end
    end
  end
end
