require 'awful/ec2'

module Stax
  module Ec2
    def self.included(thor)
      thor.class_eval do

        desc 'instances', 'list ec2 instances for this stack'
        def instances
          debug("Instances for #{stack_name}")
          ec2(:ls, [], stack: stack_name, long: true)
        end

      end
    end
  end
end