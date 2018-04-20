module Stax
  class Stack < Base

    no_commands do

      ## set this in stack to force changesets on update
      def stack_force_changeset
        false
      end

      ## can be anything unique
      def change_set_name
        stack_name + '-' + Time.now.strftime('%Y%m%d%H%M%S')
      end

      ## create a change set to update existing stack
      def change_set_update
        Aws::Cfn.changeset(
          stack_name: stack_name,
          template_body: cfn_template_body,
          template_url: cfn_template_url,
          parameters: cfn_parameters_update,
          capabilities: cfn_capabilities,
          notification_arns: cfer_notification_arns,
          change_set_name: change_set_name,
          change_set_type: :UPDATE,
        ).id
      rescue ::Aws::CloudFormation::Errors::ValidationError => e
        fail_task(e.message)
      end

      ## wait and return true if changeset ready for execute
      def change_set_complete?(id)
        begin
          Aws::Cfn.client.wait_until(:change_set_create_complete, stack_name: stack_name, change_set_name: id) { |w| w.delay = 1 }
        rescue ::Aws::Waiters::Errors::FailureStateError => e
          false                 # no changes to apply
        end
      end

      ## string to print for replacement flag
      def change_set_replacement(string)
        case string
          when 'True' then 'Replace'
          when 'Conditional' then 'May replace'
          else ''
        end
      end

      ## display planned changes
      def change_set_changes(id)
        debug("Changes to #{stack_name}")
        print_table Aws::Cfn.changes(stack_name: stack_name, change_set_name: id).map { |c|
          r = c.resource_change
          replacement = set_color(change_set_replacement(r.replacement), :red)
          [color(r.action, Aws::Cfn::COLORS), r.logical_resource_id, r.physical_resource_id, r.resource_type, replacement]
        }
      end

      ## confirm and execute the change set
      def change_set_execute(id)
        if yes?("Apply these changes to stack #{stack_name}?", :yellow)
          Aws::Cfn.execute(stack_name: stack_name, change_set_name: id)
        end
      end

      def change_set_unlock
        Aws::Cfn.set_policy(stack_name: stack_name, stack_policy_body: stack_policy_during_update)
      end

      def change_set_lock
        Aws::Cfn.set_policy(stack_name: stack_name, stack_policy_body: stack_policy)
      end
    end

    desc 'change', 'create and execute a changeset'
    def change
      id = change_set_update
      change_set_complete?(id) || fail_task('No changes')
      change_set_changes(id)
      change_set_unlock
      change_set_execute(id) && tail && warn_imports
    ensure
      change_set_lock
    end

  end
end