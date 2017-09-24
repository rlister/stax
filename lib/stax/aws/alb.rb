module Stax
  module Aws
    class Alb < Sdk

      COLORS = {
        healthy:     :green,
        unhealthy:   :red,
        unavailable: :red,
      }

      class << self

        def client
          @_client ||= ::Aws::ElasticLoadBalancingV2::Client.new
        end

        def describe(alb_arns)
          client.describe_load_balancers(load_balancer_arns: alb_arns).load_balancers
        end

        ## return instances tagged by stack with name
        def instances(name)
          # filter = {name: 'tag:aws:cloudformation:stack-name', values: [name]}
          # paginate(:reservations) do |token|
          #   client.describe_instances(filters: [filter], next_token: token)
          # end.map(&:instances).flatten
          puts "called alb instances"
        end

        def target_groups(alb_arn)
          paginate(:target_groups) do |marker|
            client.describe_target_groups(load_balancer_arn: alb_arn, marker: marker)
          end
        end

        def target_health(tg_arn)
          client.describe_target_health(target_group_arn: tg_arn).target_health_descriptions.flatten(1)
        end

        # desc 'instances NAME', 'list instances and health for ALB with NAME or ARN'
        # method_option :long, aliases: '-l', type: :boolean, default: false, desc: 'long listing'
        # def instances(name)
        #   alb.describe_target_groups(load_balancer_arn: get_arn(name)).target_groups.map do |tg|
        #     alb.describe_target_health(target_group_arn: tg.target_group_arn).target_health_descriptions
        #   end.flatten(1).output do |targets|
        #     if options[:long]
        #       print_table targets.map { |t|
        #         [t.target.id, t.target.port, color(t.target_health.state), t.target_health.reason, t.target_health.description]
        #       }
        #     else
        #       puts targets.map{ |t| t.target.id }
        #     end
        #   end
        # end

      end
    end
  end
end