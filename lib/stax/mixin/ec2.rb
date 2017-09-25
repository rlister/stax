require 'stax/aws/ec2'

module Stax
  module Ec2Tasks
    include Aws

    def self.included(thor)
      thor.class_eval do

        desc 'ec2-instances', 'EC2 instances'
        def ec2_instances
          print_table Ec2.instances(stack_name).map { |i|
            name = i.tags.find { |t| t.key == 'Name' }&.value
            [
              name,
              i.instance_id,
              i.instance_type,
              i.placement.availability_zone,
              color(i.state.name, Ec2::COLORS),
              i.private_ip_address,
              i.public_ip_address
            ]
          }
        end

      end
    end
  end
end