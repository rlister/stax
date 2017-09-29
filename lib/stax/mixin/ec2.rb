require 'stax/aws/ec2'

module Stax
  module Ec2
    def self.included(thor)
      thor.desc(:ec2, 'EC2 subcommands')
      thor.subcommand(:ec2, Cmd::Ec2)
    end
  end

  module Cmd
    class Ec2 < SubCommand

      desc 'ls', 'list instances for stack'
      def ls
        p stack_prefix
        print_table Aws::Ec2.instances(my.stack_name).map { |i|
          name = i.tags.find { |t| t.key == 'Name' }&.value
          [
            name,
            i.instance_id,
            i.instance_type,
            i.placement.availability_zone,
            color(i.state.name, COLORS),
            i.private_ip_address,
            i.public_ip_address
          ]
        }
      end
    end

  end
end