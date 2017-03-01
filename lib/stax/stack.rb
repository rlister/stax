module Stax
  class Stack < Base
    include Awful::Short

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
    end

    desc 'exists', 'test if stack exists'
    def exists
      puts exists?.to_s
    end

    desc 'create', 'create stack'
    def create
      fail_task("Stack #{stack_name} already exists") if exists?
      debug("Creating stack #{stack_name}")
      try(:key_pair_store)
      cfer_converge
      lock
    end

    desc 'update', 'update stack'
    def update
      fail_task("Stack #{stack_name} does not exist") unless exists?
      debug("Updating stack #{stack_name}")
      unlock
      cfer_converge
      lock
    end

    desc 'delete', 'delete stack'
    def delete
      cf(:delete, [stack_name])
      try(:key_pair_delete)
    end

    desc 'generate', 'generate JSON for stack template'
    def generate
      cfer_generate
    end

    desc 'tail', 'tail stack events'
    def tail
      cfer_tail
    end

    desc 'policy', 'show stack update policy'
    def policy
      cf(:policy, [stack_name])
    end

    desc 'lock', 'set a global Deny policy on stack'
    def lock
      fail_task("Stack #{stack_name} does not exist") unless exists?
      debug("Denying all updates for stack #{stack_name}")
      statement = {
        Statement: [
          Effect:    'Deny',
          Action:    'Update:*',
          Principal: '*',
          Resource:  '*'
        ]
      }
      cf(:policy, [stack_name], json: JSON.pretty_generate(statement))
    end

    desc 'unlock', 'set stack policy to allow limited resource ids to update'
    def unlock
      fail_task("Stack #{stack_name} does not exist") unless exists?
      resources = options[:resources] || %w(lc* asg*) # sane defaults
      resources = ['*'] if options[:all]
      debug("Allowing updates to #{stack_name} for resources: #{resources.join(' ')}")
      statement = {
        Statement: [
          Effect:    'Allow',
          Action:    'Update:*',
          Principal: '*',
          Resource:  resources.map { |resource| "LogicalResourceId/#{resource}" }
        ]
      }
      cf(:policy, [stack_name], json: JSON.pretty_generate(statement))
    end

    desc 'resources', 'show resources for stack'
    method_option :type,  aliases: '-t', type: :string, default: nil, desc: 'filter by resource type'
    method_option :match, aliases: '-m', type: :string, default: nil, desc: 'filter by resource regex'
    def resources
      cf(:resources, [stack_name], options.merge(long: true))
    end

    desc 'events', 'show all events for stack'
    def events
      cf(:events, [stack_name])
    rescue Aws::CloudFormation::Errors::ValidationError => e
      puts e.message
    end

    desc 'template', 'get template of existing stack from cloudformation'
    def template
      cf(:template, [stack_name])
    end

    desc 'parameters', 'show parameters for stack'
    def parameters
      cf(:parameters, [stack_name])
    end

    desc 'outputs', 'show stack output'
    def outputs
      cf(:outputs, [stack_name])
    end

    desc 'status', 'show status of ASGs and ELBs'
    def status
      try :asg_status
      try :elb_status
      try :alb_status
    end

  end
end