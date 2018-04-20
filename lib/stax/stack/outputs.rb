module Stax
  class Stack < Base

    no_commands do
      def stack_outputs
        @_stack_outputs ||= Aws::Cfn.outputs(stack_name)
      end

      def stack_output(key)
        stack_outputs.fetch(key.to_s, nil)
      end
    end

    desc 'outputs', 'show stack outputs'
    def outputs(key = nil)
      if key
        puts stack_output(key)
      else
        print_table Aws::Cfn.describe(stack_name).outputs.map { |o|
          [o.output_key, o.output_value, o.description, o.export_name]
        }.sort
      end
    end

  end
end