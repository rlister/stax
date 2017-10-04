module Stax
  module Aws
    class Alb < Sdk

      class << self

        def client
          @_client ||= ::Aws::ElasticLoadBalancingV2::Client.new
        end

        def describe(alb_arns)
          client.describe_load_balancers(load_balancer_arns: alb_arns).load_balancers
        end

        def target_groups(alb_arn)
          paginate(:target_groups) do |marker|
            client.describe_target_groups(load_balancer_arn: alb_arn, marker: marker)
          end
        end

        def target_health(tg_arn)
          client.describe_target_health(target_group_arn: tg_arn).target_health_descriptions.flatten(1)
        end

      end
    end
  end
end