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
        @_stack_name ||= stack_prefix + class_name.downcase
      end

      def exists?
        cf(:exists, [stack_name], quiet: true)
      end

      def stack_status
        cf(:status, [stack_name], quiet: true)
      end

      def stack_notification_arns
        cf(:dump, [stack_name], quiet: true)&.first&.notification_arns
      end

    end

    desc 'exists', 'test if stack exists'
    def exists
      puts exists?.to_s
    end

    desc 'status', 'show status of ASGs and ELBs'
    def status
      try :asg_status
      try :elb_status
      try :alb_status
    end

  end
end