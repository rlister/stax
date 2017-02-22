module Stax
  class Stack < Base
    include Awful::Short

    no_commands do
      def class_name
        @_class_name ||= self.class.to_s.split('::').last
      end

      def stack_name
        @_stack_name ||= cfn_safe(stack_prefix + class_name.downcase)
      end

      def exists?
        cf(:exists, [stack_name], quiet: true)
      end
    end

    desc 'exists', 'test if stack exists'
    def exists
      puts exists?.to_s
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

    desc 'outputs', 'show stack output'
    def outputs
      cf(:outputs, [stack_name])
    end
  end
end