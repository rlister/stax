require 'stax/aws/ecs'

module Stax
  module Ecs
    def self.included(thor)
      thor.desc(:ecs, 'ECS subcommands')
      thor.subcommand(:ecs, Cmd::Ecs)
    end

    def ecs_cluster_name
      'default'
    end

    def ecs_services
      @_ecs_services ||= Aws::Cfn.resources_by_type(stack_name, 'AWS::ECS::Service')
    end

    def ecs_task_definitions
      @_ecs_task_definitions ||= Aws::Cfn.resources_by_type(stack_name, 'AWS::ECS::TaskDefinition')
    end
  end

  module Cmd
    class Ecs < SubCommand
      COLORS = {
        ACTIVE:   :green,
        INACTIVE: :red,
        RUNNING:  :green,
        STOPPED:  :red,
      }

      no_commands do
        def ecs_task_definition(id)
          Aws::Cfn.id(my.stack_name, id)
        end
      end

      desc 'clusters', 'ECS cluster for stack'
      def clusters
        print_table Aws::Ecs.clusters(my.ecs_cluster_name).map { |c|
          [
            c.cluster_name,
            color(c.status, COLORS),
            "instances:#{c.registered_container_instances_count}",
            "pending:#{c.pending_tasks_count}",
            "running:#{c.running_tasks_count}",
          ]
        }
      end

      desc 'services', 'ECS services for stack'
      def services
        print_table Aws::Ecs.services(my.ecs_cluster_name, my.ecs_services.map(&:physical_resource_id)).map { |s|
          [s.service_name, color(s.status, COLORS), s.task_definition.split('/').last, "#{s.running_count}/#{s.desired_count}"]
        }
      end

      desc 'definitions', 'ECS task definitions for stack'
      def definitions
        print_table my.ecs_task_definitions.map { |r|
          t = Aws::Ecs.task_definition(r.physical_resource_id)
          [r.logical_resource_id, t.family, t.revision, color(t.status, COLORS)]
        }
      end

      desc 'tasks', 'ECS tasks for stack'
      method_option :status, aliases: '-s', type: :string, default: 'RUNNING', desc: 'status to list'
      def tasks
        print_table Aws::Ecs.tasks(my.ecs_cluster_name, options[:status].upcase).map { |t|
          [
            t.task_arn.split('/').last,
            t.task_definition_arn.split('/').last,
            t.container_instance_arn&.split('/')&.last || '--',
            color(t.last_status, COLORS),
            "(#{t.desired_status})",
            t.started_by,
          ]
        }
      end

      desc 'containers', 'containers for running tasks'
      method_option :status, aliases: '-s', type: :string, default: 'RUNNING', desc: 'status to list'
      def containers
        debug("Containers for cluster #{my.ecs_cluster_name}")
        print_table Aws::Ecs.tasks(my.ecs_cluster_name, options[:status].upcase).map { |task|
          task_defn = task.task_definition_arn.split('/').last
          task.containers.map { |c|
            [
              c.container_arn.split('/').last,
              c.name,
              color(c.last_status, COLORS),
              c.network_interfaces.map(&:private_ipv_4_address).join(','),
              task_defn,
              c.exit_code,
              c.reason,
            ]
          }
        }.flatten(1)
      end

      desc 'instances', 'ECS instances'
      def instances
        print_table Aws::Ecs.instances(my.ecs_cluster_name).map { |i|
          [
            i.container_instance_arn.split('/').last,
            i.ec2_instance_id,
            i.agent_connected,
            color(i.status, COLORS),
            i.running_tasks_count,
            "(#{i.pending_tasks_count})",
            "agent #{i.version_info.agent_version}",
            i.version_info.docker_version,
          ]
        }
      end

      desc 'run_task [ID]', 'run task by id'
      def run_task(id)
        Aws::Ecs.run(my.ecs_cluster_name, Aws::Cfn.id(my.stack_name, id)).tap do |tasks|
          puts tasks.map(&:container_instance_arn)
        end
      end

      desc 'stop_task [TASK]', 'stop task'
      def stop_task(task)
        Aws::Ecs.stop(my.ecs_cluster_name, task).tap do |task|
          puts task.container_instance_arn
        end
      end

      desc 'scale', 'scale containers for service'
      method_option :desired, aliases: '-d', type: :numeric, default: nil, desc: 'desired container count'
      def scale
        my.ecs_services.each do |s|
          debug("Scaling service #{s.logical_resource_id}")
          Aws::Ecs.client.update_service(
            service: s.physical_resource_id,
            desired_count: options[:desired],
          ).service.tap do |s|
            puts "desired: #{s.desired_count}"
          end
        end
      end

    end

  end
end