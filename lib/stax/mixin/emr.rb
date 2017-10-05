require 'stax/aws/emr'
require 'yaml'

module Stax
  module Emr
    def self.included(thor)
      thor.desc(:emr, 'Emr subcommands')
      thor.subcommand(:emr, Cmd::Emr)
    end
  end

  module Cmd
    class Emr < SubCommand

      COLORS = {
        RUNNING:                :green,
        WAITING:                :green,
        TERMINATING:            :red,
        TERMINATED:             :red,
        TERMINATED_WITH_ERRORS: :red,
      }

      no_commands do
        def stack_emr_clusters
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::EMR::Cluster')
        end
      end

      desc 'status', 'EMR cluster state'
      def status
        print_table stack_emr_clusters.map { |r|
          c = Aws::Emr.describe(r.physical_resource_id)
          [color(c.status.state, COLORS), c.status.state_change_reason.message]
        }
      end

      desc 'describe', 'describe EMR clusters'
      def describe
        stack_emr_clusters.each do |r|
          Aws::Emr.describe(r.physical_resource_id).tap do |c|
            puts YAML.dump(stringify_keys(c.to_hash))
          end
        end
      end

      desc 'groups', 'EMR instance groups'
      def groups
        stack_emr_clusters.each do |r|
          debug("Instance groups for #{r.logical_resource_id} #{r.physical_resource_id}")
          print_table Aws::Emr.groups(r.physical_resource_id).map { |g|
            [g.id, color(g.status.state, COLORS), g.name, g.instance_type, g.running_instance_count, g.market]
          }
        end
      end

      desc 'instances', 'EMR instances'
      def instances
        stack_emr_clusters.each do |r|
          debug("Instances for #{r.logical_resource_id} #{r.physical_resource_id}")
          group_names = Aws::Emr.groups(r.physical_resource_id).each_with_object({}) { |g,h| h[g.id] = g.name }
          print_table Aws::Emr.instances(r.physical_resource_id).map { |i|
            [i.id, i.ec2_instance_id, group_names[i.instance_group_id], i.instance_type, color(i.status.state, COLORS), i.public_ip_address]
          }
        end
      end

    end
  end
end
