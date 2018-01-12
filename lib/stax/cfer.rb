require 'cfer'

module Stax
  class Stack < Base
    class_option :use_previous_value, aliases: '-u', type: :array, default: [], desc: 'params to use previous value'

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

      ## override with SNS ARNs as needed
      def cfer_notification_arns
        []
      end

      def cfer_termination_protection
        false
      end

      ## create/update the stack
      def cfer_converge(args = {})
        opts = {
          parameters: stringify_keys(cfer_parameters).except(*options[:use_previous_value]),
          template:   cfer_template,
          follow:     true,
          number:     1,
          s3_path:    cfer_s3_path,
          notification_arns: cfer_notification_arns,
          enable_termination_protection: cfer_termination_protection,
        }
        Cfer.converge!(stack_name, opts.merge(args))
      end

      ## generate JSON for stack without sending to cloudformation
      def cfer_generate
        opts = {parameters: stringify_keys(cfer_parameters)}
        Cfer.generate!(cfer_template, opts)
      end

      ## generate method does puts, so steal stdout into a string
      def cfer_generate_string
        capture_stdout do
          cfer_generate
        end
      end

      def cfer_tail
        Cfer.tail!(stack_name, follow: true, number: 1)
      rescue ::Aws::CloudFormation::Errors::ValidationError => e
        puts e.message
      end

      ## temporarily grab stdout to a string
      def capture_stdout
        stdout, $stdout = $stdout, StringIO.new
        yield
        $stdout.string
      ensure
        $stdout = stdout
      end

    end

  end
end