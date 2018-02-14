require 'cfer'

module Stax
  class Stack < Base
    class_option :use_previous_value, aliases: '-u', type: :array, default: [], desc: 'params to use previous value'

    no_commands do

      def cfer_parameters
        {}
      end

      def cfn_parameters
        cfer_parameters
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

      ## location of template file
      def cfn_template_path
        File.join('cf', "#{class_name}.rb")
      end

      ## generate JSON for stack without sending to cloudformation
      def cfer_generate
        opts = {parameters: stringify_keys(cfn_parameters)}
        Cfer.generate!(cfn_template_path, opts)
      end

      ## generate method does puts, so steal stdout into a string
      def cfer_generate_string
        capture_stdout do
          cfer_generate
        end
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