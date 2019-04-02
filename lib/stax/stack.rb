module Stax
  class Stack < Base

    no_commands do

      ## get name of stack in Staxfile, or infer it from class
      def class_name
        @_class_name ||= self.class.instance_variable_get(:@name) || self.class.to_s.split('::').last.underscore
      end

      ## build valid name for the stack
      def stack_name
        @_stack_name ||= stack_prefix + cfn_safe(class_name)
      end

      ## list of other stacks we need to reference
      def stack_imports
        self.class.instance_variable_get(:@imports)
      end

      def stack_type
        self.class.instance_variable_get(:@type)
      end

      def exists?
        Aws::Cfn.exists?(stack_name)
      end

      def stack_status
        Aws::Cfn.describe(stack_name).stack_status
      end

      def stack_notification_arns
        Aws::Cfn.describe(stack_name).notification_arns
      end

      def resource(id)
        Aws::Cfn.id(stack_name, id)
      end
    end

    desc 'exists', 'test if stack exists'
    def exists
      puts exists?
    end

  end
end