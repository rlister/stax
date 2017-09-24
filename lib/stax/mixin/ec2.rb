require 'stax/aws/ec2'

module Stax
  module Ec2

    def self.included(thor)

      thor.class_eval do

        desc 'ec2-instances', 'list ec2 instances for this stack'
        def ec2_instances
          print_table Aws::Ec2.instances(stack_name).map { |i|
            name = i.tags.find { |t| t.key == 'Name' }&.value
            [
              name,
              i.instance_id,
              i.instance_type,
              i.placement.availability_zone,
              color(i.state.name, Aws::Ec2::COLORS),
              i.private_ip_address,
              i.public_ip_address
            ]
          }
        end

      end
    end
  end
end