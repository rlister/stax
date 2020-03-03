require 'aws-sdk-ecs'

module Stax
  module Aws
    class Ecs < Sdk

      class << self

        def client
          @_client ||= ::Aws::ECS::Client.new
        end

        def clusters(names)
          client.describe_clusters(clusters: Array(names)).clusters
        end

        def services(cluster, services)
          client.describe_services(cluster: cluster, services: services).services
        end

        def update_service(opt)
          client.update_service(opt).service
        end

        def task_definition(name)
          client.describe_task_definition(task_definition: name).task_definition
        end

        def list_tasks(opt)
          paginate(:task_arns) do |token|
            client.list_tasks(opt.merge(next_token: token))
          end
        end

        def tasks(opt = {})
          tasks = list_tasks(opt)
          if tasks.empty?
            []
          else
            client.describe_tasks(cluster: opt[:cluster], tasks: tasks).tasks
          end
        end

        def list_instances(cluster)
          paginate(:container_instance_arns) do |token|
            client.list_container_instances(cluster: cluster, next_token: token)
          end
        end

        def instances(cluster)
          client.describe_container_instances(cluster: cluster, container_instances: list_instances(cluster)).container_instances
        end

        def run(cluster, task)
          client.run_task(cluster: cluster, task_definition: task).tasks
        end

        def stop(cluster, task)
          client.stop_task(cluster: cluster, task: task).task
        end

      end
    end
  end
end
