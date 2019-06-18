require 'stax/aws/ecs'
require_relative 'ecs/deploy'

module Stax
  module Ecs
    def self.included(thor)
      thor.desc('ecs COMMAND', 'ECS subcommands')
      thor.subcommand(:ecs, Cmd::Ecs)
    end

    def ecs_clusters
      @_ecs_clusters ||= Aws::Cfn.resources_by_type(stack_name, 'AWS::ECS::Cluster')
    end

    def ecs_cluster_name
      @_ecs_cluster_name ||= (ecs_clusters&.first&.physical_resource_id || 'default')
    end

    def ecs_services
      @_ecs_services ||= Aws::Cfn.resources_by_type(stack_name, 'AWS::ECS::Service')
    end

    def ecs_task_definitions
      @_ecs_task_definitions ||= Aws::Cfn.resources_by_type(stack_name, 'AWS::ECS::TaskDefinition')
    end

    ## get services with a list of logical ids
    def ecs_services_with_ids(*ids)
      if ids.empty?
        ecs_services
      else
        ecs_services.select do |s|
          ids.include?(s.logical_resource_id)
        end
      end
    end

    ## mangle taskdef arn into family name
    def ecs_task_families
      ecs_task_definitions.map do |r|
        r.physical_resource_id.split(':')[-2].split('/').last
      end
    end

    def ecs_service_names
      @_ecs_service_names ||= ecs_services.map(&:physical_resource_id)
    end

    def ecs_service_objects
      Aws::Ecs.services(ecs_cluster_name, ecs_service_names)
    end

    ## deprecated: register a new revision of existing task definition
    def ecs_update_taskdef(id)
      taskdef = Aws::Ecs.task_definition(resource(id))
      debug("Registering new revision of #{taskdef.family}")
      args = %i[family cpu memory requires_compatibilities task_role_arn execution_role_arn network_mode container_definitions volumes placement_constraints]
      Aws::Ecs.client.register_task_definition(taskdef.to_hash.slice(*args)).task_definition.tap do |t|
        puts t.task_definition_arn
      end
    end

    ## deprecated: update service to use a new task definition
    def ecs_update_service(id, taskdef)
      service_name = resource(id).split('/').last
      taskdef_name = taskdef.task_definition_arn.split('/').last
      debug("Updating #{service_name} to #{taskdef_name}")
      Aws::Ecs.update_service(service: service_name, task_definition: taskdef_name).tap do |s|
        puts s.task_definition
      end
    end

  end

  module Cmd
    class Ecs < SubCommand
      stax_info :tasks

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

        def print_event(e)
          puts "#{set_color(e.created_at, :green)}  #{e.message}"
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
        print_table my.ecs_service_objects.map { |s|
          [s.service_name, color(s.status, COLORS), s.task_definition.split('/').last, "#{s.running_count}/#{s.desired_count}"]
        }
      end

      desc 'events', 'show service events'
      method_option :number, aliases: '-n', type: :numeric, default: 10, desc: 'number of events to show'
      def events
        my.ecs_service_objects.each do |s|
          debug("Events for #{s.service_name}")
          s.events.first(options[:number]).reverse.map(&method(:print_event))
        end
      end

      desc 'tail [SERVICE]', 'tail ECS events'
      def tail(service = nil)
        trap('SIGINT', 'EXIT')    # clean exit with ctrl-c
        service ||= my.ecs_service_names.first
        latest_event = Aws::Ecs.services(my.ecs_cluster_name, [service]).first.events.first
        print_event(latest_event)
        last_seen = latest_event.id
        loop do
          sleep 5
          unseen = []
          Aws::Ecs.services(my.ecs_cluster_name, [service]).first.events.each do |e|
            break if e.id == last_seen
            unseen.unshift(e)
          end
          unseen.each(&method(:print_event))
          last_seen = unseen.last.id unless unseen.empty?
        end
      end

      desc 'deployments', 'show service deployments'
      def deployments
        my.ecs_service_objects.each do |s|
          debug("Deployments for #{s.service_name}")
          print_table s.deployments.map { |d|
            count = "#{d.running_count}/#{d.desired_count} (#{d.pending_count})"
            [d.id, d.status, count, d.created_at, d.updated_at, d.task_definition.split('/').last]
          }
        end
      end

      desc 'definitions', 'ECS task definitions for stack'
      def definitions
        print_table my.ecs_task_definitions.map { |r|
          t = Aws::Ecs.task_definition(r.physical_resource_id)
          [r.logical_resource_id, t.family, t.revision, color(t.status, COLORS)]
        }
      end

      desc 'env', 'env vars for latest rev of task families'
      def env
        my.ecs_task_families.each do |family|
          Aws::Ecs.task_definition(family).container_definitions.each do |c|
            debug("Environment for #{family} #{c.name}")
            print_table c.environment.map { |e|
              [e.name, e.value]
            }.sort
          end
        end
      end

      desc 'tasks', 'ECS tasks for stack'
      method_option :status, aliases: '-s', type: :string, default: 'RUNNING', desc: 'status to list'
      def tasks
        my.ecs_services.each do |s|
          name = s.physical_resource_id.split('/').last
          debug("Tasks for service #{name}")
          Aws::Ecs.tasks(
            cluster: my.ecs_cluster_name,
            service_name: s.physical_resource_id,
            desired_status: options[:status].upcase,
          ).map { |t|
            [
              t.task_arn.split('/').last,
              t.task_definition_arn.split('/').last,
              t.container_instance_arn&.split('/')&.last || '--',
              color(t.last_status, COLORS),
              "(#{t.desired_status})",
              t.started_by,
            ]
          }.tap(&method(:print_table))
        end
      end

      desc 'containers', 'containers for running tasks'
      method_option :status, aliases: '-s', type: :string, default: 'RUNNING', desc: 'status to list'
      def containers
        my.ecs_services.each do |s|
          Aws::Ecs.tasks(
            cluster: my.ecs_cluster_name,
            service_name: s.physical_resource_id,
            desired_status: options[:status].upcase,
          ).each do |t|
            task = t.task_arn.split('/').last
            debug("Containers for task #{task}")
            print_table t.containers.map { |c|
              [
                c.name,
                c.container_arn.split('/').last,
                color(c.last_status, COLORS),
                c.network_interfaces.map(&:private_ipv_4_address).join(','),
                t.task_definition_arn.split('/').last,
                c.exit_code,
                c.reason,
              ]
            }
          end
        end
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

      desc 'scale [IDs]', 'scale containers for service'
      method_option :desired, aliases: '-d', type: :numeric, default: nil, desc: 'desired container count'
      def scale(*ids)
        my.ecs_services_with_ids(*ids).each do |s|
          debug("Scaling service #{s.physical_resource_id.split('/').last}")
          Aws::Ecs.update_service(
            cluster: my.ecs_cluster_name,
            service: s.physical_resource_id,
            desired_count: options[:desired],
          ).tap do |s|
            puts "desired: #{s.desired_count}"
          end
        end
      end

    end

  end
end