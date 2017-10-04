module Stax
  class Stack < Base

    no_commands do
      def stack_parameters
        @_stack_parameters ||= Cfn.parameters(stack_name)
      end

      def stack_parameter(key)
        stack_parameters.fetch(key.to_s, nil)
      end
    end

    desc 'parameters', 'show stack input parameters'
    def parameters
      print_table stack_parameters.each_with_object({}) { |p, h|
        h[p.parameter_key] = p.parameter_value
      }.sort
    end

  end
end