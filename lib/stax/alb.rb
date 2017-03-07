require 'awful/alb'

module Stax
  module Alb
    def self.included(thor)
      thor.class_eval do

        no_commands do
          def application_load_balancers
            @_application_load_balancers ||= cf(:resources, [stack_name], type: ['AWS::ElasticLoadBalancingV2::LoadBalancer'], quiet: true)
          end

          def alb_names
            @_alb_names ||= application_load_balancers.map do |alb|
              alb.physical_resource_id.split('/').fetch(-2)
            end
          end

          def alb_status
            application_load_balancers.each do |alb|
              debug("ALB status for #{alb.logical_resource_id}")
              alb(:instances, [alb.physical_resource_id], long: true)
            end
          end
        end

        desc 'albs', 'show ALBs for stack'
        def albs
          debug("ALBs for stack #{stack_name}")
          alb(:ls, alb_names, long: true)
        end

      end
    end
  end
end