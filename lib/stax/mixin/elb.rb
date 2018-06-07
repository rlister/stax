require 'stax/aws/elb'

module Stax
  module Elb
    def self.included(thor)
      thor.desc(:elb, 'ELB subcommands')
      thor.subcommand(:elb, Cmd::Elb)
    end
  end

  module Cmd
    class Elb < SubCommand
      stax_info :status

      COLORS = {
        InService:    :green,
        OutOfService: :red,
      }

      no_commands do
        def stack_elbs
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::ElasticLoadBalancing::LoadBalancer')
        end
      end

      desc 'dns', 'ALB DNS names'
      def dns
        puts Aws::Elb.describe(stack_elbs.map(&:physical_resource_id)).map(&:dns_name)
      end

      desc 'status', 'ELB instance status'
      def status
        stack_elbs.each do |elb|
          debug("ELB status for #{elb.logical_resource_id} #{elb.physical_resource_id}")
          print_table Aws::Elb.instance_health(elb.physical_resource_id).map { |i|
            [i.instance_id, color(i.state, COLORS), i.reason_code, i.description]
          }
        end
      end

    end
  end
end