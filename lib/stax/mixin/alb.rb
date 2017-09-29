require 'stax/aws/alb'

module Stax
  module Alb
    def self.included(thor)
      thor.desc(:alb, 'ALB subcommands')
      thor.subcommand(:alb, Cmd::Alb)
    end
  end

        no_commands do
          def stack_albs
            Cfn.resources_by_type(stack_name, 'AWS::ElasticLoadBalancingV2::LoadBalancer')
          end
        end
  module Cmd
    class Alb < SubCommand


      no_commands do
        def stack_albs
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::ElasticLoadBalancingV2::LoadBalancer')
        end
      end

      desc 'dns', 'ALB DNS names'
      def dns
        puts Aws::Alb.describe(stack_albs.map(&:physical_resource_id)).map(&:dns_name)
      end

      desc 'status', 'ALB instance status'
      def status
        stack_albs.each do |alb|
          Aws::Alb.target_groups(alb.physical_resource_id).each do |t|
            debug("ALB status for #{alb.logical_resource_id} #{t.protocol}:#{t.port} #{t.target_group_name}")
            print_table Aws::Alb.target_health(t.target_group_arn).map { |h|
              [h.target.id, h.target.port, color(h.target_health.state, COLORS), h.target_health.reason, h.target_health.description]
            }
          end
        end
      end

    end
  end
end