require 'cfer'

module Stax
  class Stack < Base

    no_commands do
      def cfer_parameters
        {}
      end

      ## location of cfer template file
      def cfer_template
        File.join('cf', "#{stack_name}.rb")
      end

      ## create/update the stack
      def cfer_converge(args = {})
        opts = {
          parameters: stringify_keys(cfer_parameters),
          template:   cfer_template,
          follow:     true,
          number:     1,
        }
        p opts.merge(args)
        # Cfer.converge!(stack_name, opts.merge(args))
      end

      ## generate JSON for stack without sending to cloudformation
      def cfer_generate
        opts = {parameters: stringify_keys(cfer_parameters)}
        Cfer.generate!(cfer_template, opts)
      end
    end

  end
end