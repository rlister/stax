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

        def list_tasks(cluster, status = :RUNNING)
          paginate(:task_arns) do |token|
            client.list_tasks(cluster: cluster, next_token: token, desired_status: status)
          end
        end

        def tasks(cluster, status = :RUNNING)
          tasks = list_tasks(cluster, status)
          if tasks.empty?
            []
          else
            client.describe_tasks(cluster: cluster, tasks: tasks).tasks
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