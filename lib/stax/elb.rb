require 'awful/elb'

module Stax
  module Elb
    def self.included(thor)
      thor.class_eval do

        no_commands do
          def load_balancers
            @_load_balancers ||= cf(:resources, [stack_name], type: ['AWS::ElasticLoadBalancing::LoadBalancer'], quiet: true)
          end

          def elb_status
            load_balancers.each do |elb|
              debug("ELB status for #{elb.physical_resource_id}")
              elb(:instances, [elb.physical_resource_id], long: true)
            end
          end
        end

        desc 'elbs', 'show DNS name for stack ELBs'
        def elbs
          debug("ELBs for stack #{stack_name}")
          load_balancers.each do |elb|
            debug("DNS name for #{elb.logical_resource_id}")
            elb(:dns, [elb.physical_resource_id])
          end
        end

      end
    end
  end
end