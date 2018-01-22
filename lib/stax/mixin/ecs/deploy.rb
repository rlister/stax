module Stax
  module Ecs

    ## convert to hash for registering new taskdef
    def taskdef_to_hash(taskdef)
      args = %i[family cpu memory requires_compatibilities task_role_arn execution_role_arn network_mode container_definitions volumes placement_constraints]
      taskdef.to_hash.slice(*args)
    end

    def get_taskdef(service)
      debug("Current task definition for #{service.service_name}")
      Aws::Ecs.task_definition(service.task_definition).tap do |t|
        puts t.task_definition_arn
      end
    end

    def register_taskdef(hash)
      debug("Registering new revision")
      Aws::Ecs.client.register_task_definition(hash).task_definition.tap do |t|
        puts t.task_definition_arn
      end
    end

    def update_service(service, taskdef)
      debug("Updating #{service.service_name} to new revision")
      Aws::Ecs.update_service(service: service.service_name, task_definition: t.task_definition_arn).tap do |s|
        puts s.deployments.first.id
      end
    end

    ## update taskdef for a service, triggering a deploy
    ## modify current taskdef in block
    def ecs_deploy(id, &block)
      service = Aws::Ecs.services(ecs_cluster_name, [resource(id)]).first
      taskdef = get_taskdef(service)

      ## convert to a hash and modify in block
      hash = taskdef_to_hash(taskdef)
      yield(hash) if block_given?

      taskdef = register_taskdef(hash)
      update_service(service, taskdef)
    end

  end
end