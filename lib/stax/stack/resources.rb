module Stax
  class Stack < Base

    no_commands do
      def stack_resources
        @_stack_resources ||= Aws::Cfn.resources(stack_name)
      end

      def stack_resources_by_type(type)
        stack_resources.select do |r|
          r.resource_type == type
        end
      end
    end

    desc 'resources', 'list resources for this stack'
    method_option :match, aliases: '-m', type: :string, default: nil, desc: 'filter by resource regex'
    def resources
      print_table stack_resources.tap { |resources|
        if options[:match]
          m = Regexp.new(options[:match], Regexp::IGNORECASE)
          resources.select! { |r| m.match(r.resource_type) }
        end
      }.map { |r|
        [r.logical_resource_id, r.resource_type, color(r.resource_status, Aws::Cfn::COLORS), r.physical_resource_id]
      }
    end

    desc 'id [LOGICAL_ID]', 'get physical ID from resource logical ID'
    def id(resource)
      puts Aws::Cfn.id(stack_name, resource)
    end

  end
end