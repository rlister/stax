require 'stax/aws/elb'

module Stax
  module ElbTasks
    include Aws

    def self.included(thor)
      thor.class_eval do

        no_commands do
          def stack_elbs
            Cfn.resources_by_type(stack_name, 'AWS::ElasticLoadBalancing::LoadBalancer')
          end
        end

        desc 'elb-dns', 'ELB DNS names'
        def elb_dns
          puts Elb.describe(stack_elbs.map(&:physical_resource_id)).map(&:dns_name)
        end

        desc 'elb-status', 'ELB instance status'
        def elb_status
          stack_elbs.each do |elb|
            debug("ELB status for #{elb.logical_resource_id} #{elb.physical_resource_id}")
            print_table Elb.instance_health(elb.physical_resource_id).map { |i|
              [i.instance_id, color(i.state, Elb::COLORS), i.reason_code, i.description]
            }
          end
        end

      end
    end

  end
end