require 'stax/aws/dms'

module Stax
  module Dms
    def self.included(thor)
      thor.desc('dms COMMAND', 'DMS subcommands')
      thor.subcommand(:dms, Cmd::Dms)
    end

    def stack_dms_endpoints
      @_stack_dms_endpoints ||= Aws::Cfn.resources_by_type(stack_name, 'AWS::DMS::Endpoint')
    end

    def stack_dms_replication_instances
      @_stack_dms_replication_instances ||= Aws::Cfn.resources_by_type(stack_name, 'AWS::DMS::ReplicationInstance')
    end

    def stack_dms_replication_tasks
      @_stack_dms_replication_tasks ||= Aws::Cfn.resources_by_type(stack_name, 'AWS::DMS::ReplicationTask')
    end
  end

  module Cmd
    class Dms < SubCommand
      stax_info :endpoints, :instances, :tasks

      COLORS = {
        active:     :green,
        available:  :green,
        successful: :green,
        failed:     :red,
        stopped:    :red,
      }

      no_commands do
        def dms_endpoint_arns
          my.stack_dms_endpoints.map(&:physical_resource_id)
        end

        def dms_instance_arns
          my.stack_dms_replication_instances.map(&:physical_resource_id)
        end

        def dms_task_arns
          my.stack_dms_replication_tasks.map(&:physical_resource_id)
        end
      end

      desc 'endpoints', 'list endpoints'
      def endpoints
        debug("DMS endpoints for #{my.stack_name}")
        print_table Aws::Dms.endpoints(filters: [{name: 'endpoint-arn', values: dms_endpoint_arns}]).map { |e|
          [e.endpoint_identifier, e.endpoint_type, color(e.status, COLORS), e.engine_name, e.server_name]
        }
      end

      desc 'instances', 'list replication instances'
      def instances
        debug("DMS replication instances for #{my.stack_name}")
        print_table Aws::Dms.instances(filters: [{name: 'replication-instance-arn', values: dms_instance_arns}]).map { |i|
          [
            i.replication_instance_identifier, color(i.replication_instance_status, COLORS),
            i.replication_subnet_group&.vpc_id, i.replication_instance_class, i.engine_version,
            i.availability_zone, i.replication_instance_private_ip_address,
          ]
        }
      end

      desc 'tasks', 'list replication tasks'
      def tasks
        debug("DMS replication tasks for #{my.stack_name}")
        print_table Aws::Dms.tasks(filters: [{name: 'replication-task-arn', values: dms_task_arns}]).map { |t|
          [
            t.replication_task_identifier, color(t.status, COLORS), t.migration_type,
            "#{t.replication_task_stats.full_load_progress_percent}%", "#{(t.replication_task_stats.elapsed_time_millis/1000).to_i}s",
            "#{t.replication_task_stats.tables_loaded} loaded", "#{t.replication_task_stats.tables_loaded} errors",
          ]
        }
      end

      desc 'test', 'test endpoint connections'
      def test
        instance = dms_instance_arns.first # FIXME: handle multiple instances
        dms_endpoint_arns.each do |endpoint|
          debug("Testing connection for #{endpoint}")
          conn = Aws::Dms.test(replication_instance_arn: instance, endpoint_arn: endpoint)
          loop do
            sleep 3
            c = Aws::Dms.connections(
              filters: [
                { name: 'endpoint-arn',             values: [conn.endpoint_arn] },
                { name: 'replication-instance-arn', values: [conn.replication_instance_arn] },
              ]
            ).first
            puts [c.endpoint_identifier, c.replication_instance_identifier, color(c.status, COLORS), c.last_failure_message].join('  ')
            break unless c.status == 'testing'
          end
        end
      end

      desc 'connections', 'list endpoint test connections'
      def connections
        debug("Test connection results for #{my.stack_name}")
        print_table Aws::Dms.connections(filters: [{name: 'endpoint-arn', values: dms_endpoint_arns}]).map { |c|
          [c.endpoint_identifier, c.replication_instance_identifier, color(c.status, COLORS), c.last_failure_message]
        }
      end

    end
  end
end