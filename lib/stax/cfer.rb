require 'cfer'

module Stax
  class Stack < Base

    no_commands do
      def cfer_parameters
        {}
      end

      ## location of cfer template file
      def cfer_template
        File.join('cf', "#{class_name}.rb")
      end

      ## override with S3 bucket for upload of large templates as needed
      def cfer_s3_path
        nil
      end

      ## create/update the stack
      def cfer_converge(args = {})
        opts = {
          parameters: stringify_keys(cfer_parameters),
          template:   cfer_template,
          follow:     true,
          number:     1,
          s3_path:    cfer_s3_path,
        }
        Cfer.converge!(stack_name, opts.merge(args))
      end

      ## generate JSON for stack without sending to cloudformation
      def cfer_generate
        opts = {parameters: stringify_keys(cfer_parameters)}
        Cfer.generate!(cfer_template, opts)
      end

      def cfer_tail
        Cfer.tail!(stack_name, follow: true, number: 1)
      rescue Aws::CloudFormation::Errors::ValidationError => e
        puts e.message
      end
    end

  end
end