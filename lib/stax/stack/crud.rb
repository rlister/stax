module Stax
  class Stack < Base

    no_commands do

      ## policy to lock the stack to all updates
      def stack_policy
        {
          Statement: [
            Effect:    'Deny',
            Action:    'Update:*',
            Principal: '*',
            Resource:  '*'
          ]
        }.to_json
      end

      ## temporary policy during updates; modify this to restrict resources
      def stack_policy_during_update
        {
          Statement: [
            Effect:    'Allow',
            Action:    'Update:*',
            Principal: '*',
            Resource:  '*'
          ]
        }.to_json
      end

      ## cleanup sometimes needs to wait
      def wait_for_delete(seconds = 5)
        return unless exists?
        debug("Waiting for #{stack_name} to delete")
        loop do
          sleep(seconds)
          break unless exists?
        end
      end

    end

    desc 'create', 'create stack'
    def create
      fail_task("Stack #{stack_name} already exists") if exists?
      debug("Creating stack #{stack_name}")
      Aws::Cfn.create(
        stack_name: stack_name,
        template_body: cfer_generate_string,
        parameters: stringify_keys(cfer_parameters).except(*options[:use_previous_value]),
        stack_policy_body: stack_policy,
        notification_arns: cfer_notification_arns,
        enable_termination_protection: cfer_termination_protection,
      )
      cfer_tail
    rescue ::Aws::CloudFormation::Errors::ValidationError => e
      warn(e.message)
    end

    desc 'update', 'update stack'
    def update
      fail_task("Stack #{stack_name} does not exist") unless exists?
      debug("Updating stack #{stack_name}")
      Aws::Cfn.update(
        stack_name: stack_name,
        template_body: cfer_generate_string,
        parameters: stringify_keys(cfer_parameters).except(*options[:use_previous_value]),
        stack_policy_during_update_body: stack_policy_during_update,
        notification_arns: cfer_notification_arns,
      )
      cfer_tail
    rescue ::Aws::CloudFormation::Errors::ValidationError => e
      warn(e.message)
    end

    desc 'delete', 'delete stack'
    def delete
      if yes? "Really delete stack #{stack_name}?", :yellow
        Aws::Cfn.delete(stack_name)
      end
    rescue ::Aws::CloudFormation::Errors::ValidationError => e
      fail_task(e.message)
    end

    desc 'tail', 'tail stack events'
    def tail
      cfer_tail
    end

    desc 'generate', 'generate cloudformation template'
    def generate
      cfer_generate
    end

    desc 'protection', 'show/set termination protection for stack'
    method_option :enable,  aliases: '-e', type: :boolean, default: nil, desc: 'enable termination protection'
    method_option :disable, aliases: '-d', type: :boolean, default: nil, desc: 'disable termination protection'
    def protection
      if options[:enable]
        Aws::Cfn.protection(stack_name, true)
      elsif options[:disable]
        Aws::Cfn.protection(stack_name, false)
      end
      debug("Termination protection for #{stack_name}")
      puts Aws::Cfn.describe(stack_name)&.enable_termination_protection
    end

  end
end