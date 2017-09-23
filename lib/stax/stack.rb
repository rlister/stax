module Stax
  class Stack < Base
    include Awful::Short
    include Aws

    class_option :resources, type: :array,   default: nil,   desc: 'resources IDs to allow updates'
    class_option :all,       type: :boolean, default: false, desc: 'DANGER: allow updates to all resources'

    no_commands do
      def class_name
        @_class_name ||= self.class.to_s.split('::').last
      end

      def stack_name
        @_stack_name ||= cfn_safe(stack_prefix + class_name.downcase)
      end

      def stack_parameters
        @_stack_parameters ||= cf(:parameters, [stack_name], quiet: true)
      end

      def stack_parameter(key)
        stack_parameters.fetch(key.to_s, nil)
      end

      def stack_outputs
        @_stack_outputs ||= cf(:outputs, [stack_name], quiet: true)
      end

      def stack_output(key)
        stack_outputs.fetch(key.to_s, nil)
      end

      def stack_status
        cf(:status, [stack_name], quiet: true)
      end

      def stack_notification_arns
        cf(:dump, [stack_name], quiet: true)&.first&.notification_arns
      end

      def exists?
        cf(:exists, [stack_name], quiet: true)
      end

      def wait_for_delete(seconds = 5)
        return unless exists?
        debug("Waiting for #{stack_name} to delete")
        loop do
          sleep(seconds)
          break unless exists?
        end
      end

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

      ## temporary policy during updates
      def stack_policy_during_update
        {
          Statement: [
            Effect:    'Allow',
            Action:    'Update:*',
            Principal: '*',
            Resource:  stack_update_resources
          ]
        }
      end

      ## resources to unlock during update
      def stack_update_resources
        if options[:all]
          ['*']
        else
          options[:resources] || stack_update_default_resources
        end.map do |r|
          "LogicalResourceId/#{r}"
        end
      end

      ## default value for --resources
      def stack_update_default_resources
        %w(lc* asg*)
      end
    end

    # desc 'name', 'return stack name'
    # def name
    #   puts stack_name
    # end

    desc 'exists', 'test if stack exists'
    def exists
      puts exists?.to_s
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

    desc 'policy', 'show stack update policy'
    def policy
      cf(:policy, [stack_name])
    end

    desc 'lock', 'set a global Deny policy on stack'
    def lock
      debug("Denying all updates for stack #{stack_name}")
      cf(:policy, [stack_name], json: JSON.pretty_generate(stack_policy))
    end

    desc 'unlock', 'set stack policy to allow limited resource ids to update'
    def unlock
      debug("Allowing updates to #{stack_name}")
      cf(:policy, [stack_name], json: JSON.pretty_generate(stack_policy_during_update))
    end

    desc 'status', 'show status of ASGs and ELBs'
    def status
      try :asg_status
      try :elb_status
      try :alb_status
    end

  end
end