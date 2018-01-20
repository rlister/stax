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
        }
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
        }
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
      cfer_converge(stack_policy: stack_policy)
    end

    desc 'update', 'update stack'
    def update
      fail_task("Stack #{stack_name} does not exist") unless exists?
      debug("Updating stack #{stack_name}")
      cfer_converge(stack_policy_during_update: stack_policy_during_update)
    end

    desc 'delete', 'delete stack'
    def delete
      if yes? "Really delete stack #{stack_name}?", :yellow
        Cfn.delete(stack_name)
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
        Cfn.protection(stack_name, true)
      elsif options[:disable]
        Cfn.protection(stack_name, false)
      end
      debug("Termination protection for #{stack_name}")
      puts Cfn.describe(stack_name)&.enable_termination_protection
    end

  end
end