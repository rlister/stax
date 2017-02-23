require 'awful/alb'

module Stax
  module Alb
    def self.included(thor)
      thor.class_eval do

        no_commands do
          def app_load_balancers
            @_app_load_balancers ||= cf(:resources, [stack_name], type: 'AWS::ElasticLoadBalancingV2::LoadBalancer', quiet: true)
          end

          def alb_arns
            app_load_balancers.each_with_object({}) do |alb, h|
              h[alb.logical_resource_id] = alb.physical_resource_id
            end
          end

          def alb_status
            alb_arns.each do |id, arn|
              debug("ALB status for #{stack_name} #{id}")
              alb(:instances, [arn], long: true)
            end
          end
        end

        desc 'albs', 'show ALBs for stack'
        def albs
          debug("ELBs for stack #{stack_name}")
          p app_load_balancers
        end

      end
    end
  end
end
