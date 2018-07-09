require 'stax/aws/rds'

module Stax
  module Rds
    def self.included(thor)
      thor.desc('rds COMMAND', 'RDS subcommands')
      thor.subcommand(:rds, Cmd::Rds)
    end
  end

  module Cmd
    class Rds < SubCommand
      stax_info :instances

      COLORS = {
        available: :green,
      }

      no_commands do
        def stack_db_instances
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::RDS::DBInstance')
        end

        def stack_rds_instances
          filter = { name: 'db-instance-id', values: stack_db_instances.map(&:physical_resource_id) }
          Aws::Rds.instances(filters: [filter])
        end
      end

      desc 'instances', 'list db instances for stack'
      def instances
        debug("RDS DB instances for #{my.stack_name}")
        print_table stack_rds_instances.map { |i|
          [i.db_instance_identifier, i.engine, i.engine_version, color(i.db_instance_status, COLORS), i.db_instance_class, i.db_subnet_group&.vpc_id, "ha:#{i.multi_az.to_s}"]
        }
      end

      desc 'endpoints', 'list db instance endpoints'
      def endpoints
        debug("RDS DB endpoints for #{my.stack_name}")
        print_table stack_rds_instances.map { |i|
          [i.db_instance_identifier, i.endpoint&.address, i.endpoint&.port, i.endpoint&.hosted_zone_id]
        }
      end


    end
  end
end