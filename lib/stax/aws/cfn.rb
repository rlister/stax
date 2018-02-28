module Stax
  module Aws
    class Cfn < Sdk

      ## stack statuses that are not DELETE_COMPLETE
      STATUSES = %i[
        CREATE_IN_PROGRESS CREATE_FAILED CREATE_COMPLETE
        ROLLBACK_IN_PROGRESS ROLLBACK_FAILED ROLLBACK_COMPLETE
        DELETE_IN_PROGRESS DELETE_FAILED
        UPDATE_IN_PROGRESS UPDATE_COMPLETE_CLEANUP_IN_PROGRESS UPDATE_COMPLETE
        UPDATE_ROLLBACK_IN_PROGRESS UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS UPDATE_ROLLBACK_COMPLETE
        REVIEW_IN_PROGRESS
      ]

      COLORS = {
        ## stack status
        CREATE_COMPLETE:      :green,
        DELETE_COMPLETE:      :green,
        UPDATE_COMPLETE:      :green,
        CREATE_FAILED:        :red,
        DELETE_FAILED:        :red,
        UPDATE_FAILED:        :red,
        ROLLBACK_IN_PROGRESS: :red,
        ROLLBACK_COMPLETE:    :red,
        ## resource action
        Add:    :green,
        Modify: :yellow,
        Remove: :red,
      }

      class << self

        def client
          @_client ||= ::Aws::CloudFormation::Client.new
        end

        def stacks
          paginate(:stack_summaries) do |token|
            client.list_stacks(stack_status_filter: STATUSES, next_token: token)
          end
        end

        def template(name)
          client.get_template(stack_name: name).template_body
        end

        def resources(name)
          paginate(:stack_resource_summaries) do |token|
            client.list_stack_resources(stack_name: name, next_token: token)
          end
        end

        def resources_by_type(name, type)
          resources(name).select do |r|
            r.resource_type == type
          end
        end

        def events(name)
          paginate(:stack_events) do |token|
            client.describe_stack_events(stack_name: name, next_token: token)
          end
        end

        def id(name, id)
          client.describe_stack_resource(stack_name: name, logical_resource_id: id).stack_resource_detail.physical_resource_id
        end

        def parameters(name)
          client.describe_stacks(stack_name: name).stacks.first.parameters
        end

        def describe(name)
          client.describe_stacks(stack_name: name).stacks.first
        end

        def exists?(name)
          Aws::Cfn.describe(name) && true
        rescue ::Aws::CloudFormation::Errors::ValidationError
          false
        end

        def outputs(name)
          describe(name).outputs.each_with_object(HashWithIndifferentAccess.new) do |o, h|
            h[o.output_key] = o.output_value
          end
        end

        def output(name, key)
          outputs(name)[key]
        end

        def validate(opt)
          client.validate_template(opt)
        end

        def create(opt)
          client.create_stack(opt)&.stack_id
        end

        def update(opt)
          client.update_stack(opt)&.stack_id
        end

        def delete(name)
          client.delete_stack(stack_name: name)
        end

        def protection(name, enable)
          client.update_termination_protection(stack_name: name, enable_termination_protection: enable)
        end

        def list_change_sets(name)
          paginate(:summaries) do |next_token|
            client.list_change_sets(stack_name: name, next_token: next_token)
          end
        end

        def changes(opt)
          paginate(:changes) do |next_token|
            client.describe_change_set(opt.merge(next_token: next_token))
          end
        end

        def changeset(opt)
          client.create_change_set(opt)
        end

        def execute(opt)
          client.execute_change_set(opt)
        end

      end

    end
  end
end