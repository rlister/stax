require 'awful/ecs'

module Stax
  module Ecs
    include Awful::Short

    def self.included(thor)
      thor.class_eval do

        no_commands do
          def ecs_cluster_name
            @_ecs_cluster_name ||= stack_name
          end

          ## lookup taskdef ARN from stack resources, and convert to task family name
          def ecs_task_definition(logical_id)
            cf(:id, [stack_name, logical_id], quiet: true).split(':')[-2].split('/').last
          end

          def ecs_tasks
            @_ecs_tasks ||= ecs(:tasks, [ecs_cluster_name], quiet: true)
          end

          def ecs_list_tasks
            debug("ECS tasks running in cluster #{ecs_cluster_name}")
            ecs(:tasks, [ecs_cluster_name], long: true)
          end

          def ecs_run_task(id)
            taskdef = ecs_task_definition(prepend(:task, id))
            debug("Run task #{taskdef} on #{ecs_cluster_name}")
            ecs(:run_task, [ecs_cluster_name, taskdef])
          end

          def ecs_stop_task(task)
            debug("Stopping task #{task} in cluster #{ecs_cluster_name}")
            ecs(:stop_task, [ecs_cluster_name, task], quiet: true)
          end
        end

        desc 'cluster', 'show ECS cluster for this stack'
        def cluster
          debug("Cluster #{ecs_cluster_name}")
          ecs(:ls, [ecs_cluster_name], long: true)
        end

        desc 'agents', 'list ECS instances in cluster'
        def agents
          debug("Instances with ecs-agent registered for #{ecs_cluster_name}")
          ecs(:instances, [ecs_cluster_name], long: true)
        end

        desc 'services', 'list ECS services on for this cluster'
        def services
          debug("Services on cluster #{ecs_cluster_name}")
          ecs(:services, [ecs_cluster_name], long: true)
        end

        desc 'definitions', 'list task definitions for this stack'
        def definitions
          debug("ECS task definitions in #{stack_name}")
          cf(:resources, [stack_name], type: 'AWS::ECS::TaskDefinition', long: true)
        end

        desc 'tasks', 'list/run/stop ECS tasks for this cluster'
        method_option :run,  type: :string, default: nil, desc: 'run task with given ID'
        method_option :stop, type: :string, default: nil, desc: 'stop task with given ID'
        def tasks
          if options[:stop]
            ecs_stop_task(options[:stop])
          elsif options[:run]
            ecs_run_task(options[:run])
          else
            ecs_list_tasks
          end
        end

      end
    end
  end
end