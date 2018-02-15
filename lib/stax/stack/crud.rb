module Stax
  class Stack < Base

    no_commands do

      ## policy to lock the stack to all updates
      def stack_policy
        {
          Statement: [
            Effect:    'Deny',
            Action:    'Update:*',
            Principal: '*',
            Resource:  '*'
          ]
        }.to_json
      end

      ## temporary policy during updates; modify this to restrict resources
      def stack_policy_during_update
        {
          Statement: [
            Effect:    'Allow',
            Action:    'Update:*',
            Principal: '*',
            Resource:  '*'
          ]
        }.to_json
      end

      ## cleanup sometimes needs to wait
      def wait_for_delete(seconds = 5)
        return unless exists?
        debug("Waiting for #{stack_name} to delete")
        loop do
          sleep(seconds)
          break unless exists?
        end
      end

      def cfn_parameters_create
        cfn_parameters.map do |k,v|
          { parameter_key: k, parameter_value: v }
        end
      end

      def cfn_parameters_update
        cfn_parameters.map do |k,v|
          if options[:use_previous_value].include?(k.to_s)
            { parameter_key: k, use_previous_value: true }
          else
            { parameter_key: k, parameter_value: v }
          end
        end
      end

      ## memoized template
      def cfn_template
        @_cfn_template ||= cfer_generate
      end

      ## set this to always do an S3 upload of template
      def cfn_force_s3?
        false
      end

      ## decide if we are uploading template to S3
      def cfn_use_s3?
        cfn_force_s3? || (cfn_template.bytesize > 51200)
      end

      ## set this for template uploads as needed, e.g. s3://bucket-name/stax/#{stack_name}"
      def cfn_s3_path
        nil
      end

      ## upload template to S3 and return public url of new object
      def cfn_s3_upload
        fail_task('No S3 bucket set for template upload: please set cfn_s3_path') unless cfn_s3_path
        uri = URI(cfn_s3_path)
        obj = ::Aws::S3::Object.new(bucket_name: uri.host, key: uri.path.sub(/^\//, ''))
        obj.put(body: cfn_template)
        obj.public_url + ((v = obj.version_id) ? "?versionId=#{v}" : '')
      end

      ## template body, or nil if uploading to S3
      def cfn_template_body
        @_cfn_template_body ||= cfn_use_s3? ? nil : cfn_template
      end

      ## template S3 URL, or nil if not uploading to S3
      def cfn_template_url
        @_cfn_template_url ||= cfn_use_s3? ? cfn_s3_upload : nil
      end

      ## validate template, and return list of require capabilities
      def cfn_capabilities
        validate.capabilities
      end

    end

    desc 'validate', 'validate template'
    def validate
      Aws::Cfn.validate(template_body: cfer_generate)
    rescue ::Aws::CloudFormation::Errors::ValidationError => e
      fail_task(e.message)
    end

    desc 'create', 'create stack'
    def create
      fail_task("Stack #{stack_name} already exists") if exists?
      debug("Creating stack #{stack_name}")
      Aws::Cfn.create(
        stack_name: stack_name,
        template_body: cfn_template_body,
        template_url: cfn_template_url,
        parameters: cfn_parameters_create,
        capabilities: cfn_capabilities,
        stack_policy_body: stack_policy,
        notification_arns: cfer_notification_arns,
        enable_termination_protection: cfer_termination_protection,
      )
      tail
    rescue ::Aws::CloudFormation::Errors::ValidationError => e
      warn(e.message)
    end

    desc 'update', 'update stack'
    def update
      fail_task("Stack #{stack_name} does not exist") unless exists?
      debug("Updating stack #{stack_name}")
      Aws::Cfn.update(
        stack_name: stack_name,
        template_body: cfn_template_body,
        template_url: cfn_template_url,
        parameters: cfn_parameters_update,
        capabilities: cfn_capabilities,
        stack_policy_during_update_body: stack_policy_during_update,
        notification_arns: cfer_notification_arns,
      )
      tail
    rescue ::Aws::CloudFormation::Errors::ValidationError => e
      warn(e.message)
    end

    desc 'delete', 'delete stack'
    def delete
      if yes? "Really delete stack #{stack_name}?", :yellow
        Aws::Cfn.delete(stack_name)
        tail
      end
    rescue ::Aws::CloudFormation::Errors::ValidationError => e
      fail_task(e.message)
    end

    desc 'generate', 'generate cloudformation template'
    def generate
      puts cfer_generate
    end

    desc 'protection', 'show/set termination protection for stack'
    method_option :enable,  aliases: '-e', type: :boolean, default: nil, desc: 'enable termination protection'
    method_option :disable, aliases: '-d', type: :boolean, default: nil, desc: 'disable termination protection'
    def protection
      if options[:enable]
        Aws::Cfn.protection(stack_name, true)
      elsif options[:disable]
        Aws::Cfn.protection(stack_name, false)
      end
      debug("Termination protection for #{stack_name}")
      puts Aws::Cfn.describe(stack_name)&.enable_termination_protection
    end

  end
end