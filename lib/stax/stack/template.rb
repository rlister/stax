module Stax
  class Stack < Base

    no_commands do
      ## location of templates relative to Staxfile
      def cfn_template_dir
        'cf'
      end

      ## template filename without extension
      def cfn_template_stub
        @_cfn_template_stub ||= File.join(cfn_template_dir, "#{class_name}")
      end

      ## load a yaml template
      def cfn_template_yaml
        if File.exist?(f = "#{cfn_template_stub}.yaml")
          File.read(f)
        end
      end

      ## load a json template
      def cfn_template_json
        if File.exist?(f = "#{cfn_template_stub}.json")
          File.read(f)
        end
      end

      ## load a ruby cfer template
      def cfn_template_cfer
        if File.exist?(f = "#{cfn_template_stub}.rb")
          cfer_generate(f)
        end
      end

      ## by default look for cdk templates in same dir as Staxfile
      def cfn_cdk_dir
        Stax.root_path
      end

      ## transcompile and load a cdk template
      def cfn_template_cdk
        Dir.chdir(cfn_cdk_dir) do
          %x[npm run build]
          %x[cdk synth]
        end
      end

      ## try to guess template by filename
      def cfn_template_guess
        cfn_template_cfer || cfn_template_yaml || cfn_template_json
      end

      ## get cfn template based on stack type
      def cfn_template
        @_cfn_template ||= \
        begin
          if stack_type
            send("cfn_template_#{stack_type}")
          else
            cfn_template_guess || fail_task('cannot find template')
          end
        end
      end

    end
  end
end
