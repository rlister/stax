module Stax
  module Aws
    class Elb < Sdk

      COLORS = {
        InService:    :green,
        OutOfService: :red,
      }

      class << self

        def client
          @_client ||= ::Aws::ElasticLoadBalancing::Client.new
        end

        def describe(elb_names)
          paginate(:load_balancer_descriptions) do |marker|
            client.describe_load_balancers(load_balancer_names: elb_names, marker: marker)
          end
        end

        def instance_health(elb_name)
          client.describe_instance_health(load_balancer_name: elb_name).instance_states
        end

      end

    end
  end
end