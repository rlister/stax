require 'stax/aws/asg'

module Stax
  module Asg
    def self.included(thor)
      thor.desc(:asg, 'ASG subcommands')
      thor.subcommand(:asg, Cmd::Asg)
    end
  end

  module Cmd
    class Asg < SubCommand
      COLORS = {
        ## lifecycle states
        Pending: :yellow, InService: :green, Terminating: :red,
        ## health statuses
        Healthy: :green, Unhealthy: :red,
        ## same for asg instances describe
        HEALTHY: :green, UNHEALTHY: :red,
        ## activity status
        Successful: :green, Failed: :red, Cancelled: :red,
        ## instance state
        running: :green, stopped: :yellow, terminated: :red,
      }

      no_commands do
        def stack_asgs
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::AutoScaling::AutoScalingGroup')
        end
      end

      desc 'ls', 'list ASGs for stack'
      def ls
        print_table Aws::Asg.describe(stack_asgs.map(&:physical_resource_id)).map { |a|
          [
            a.auto_scaling_group_name[0,40],
            a.launch_configuration_name[0,40],
            "#{a.instances.length}/#{a.desired_capacity}",
            "#{a.min_size}-#{a.max_size}",
            a.availability_zones.map{ |az| az[-1,1] }.sort.join(','),
            a.created_time
          ]
        }
      end

      desc 'status', 'status of instances by ASG'
      def status
        stack_asgs.each do |asg|
          debug("ASG status for #{asg.physical_resource_id}")
          print_table Aws::Asg.instances(asg.physical_resource_id).map { |i|
            [
              i.instance_id,
              i.availability_zone,
              color(i.lifecycle_state, COLORS),
              color(i.health_status, COLORS),
              i.launch_configuration_name,
            ]
          }
        end
      end

      desc 'old', 'ASG instances with outdated launch config'
      def old
        # TODO
      end

      desc 'scale', 'scale ASG desired count'
      def scale
        # TODO
      end

    end
  end
end