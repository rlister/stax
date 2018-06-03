require 'cfer'

## TODO: remove these hacks once merged and released in upstream cfer
## see cfer PRs: #52, #54
module Cfer::Core::Functions
  def get_azs(region = '')
    {"Fn::GetAZs" => region}
  end

  def cidr(ip_block, count, size_mask)
    {"Fn::Cidr" => [ip_block, count, size_mask]}
  end

  def import_value(value)
    {"Fn::ImportValue" => value}
  end

  def split(*args)
    {"Fn::Split" => [ *args ].flatten }
  end
end

## see cfer PR: #56
module Cfer::Core
  class Stack < Cfer::Block
    def output(name, value, options = {})
      opt = options.each_with_object({}) { |(k,v),h| h[k.to_s.capitalize] = v } # capitalize all keys
      export = opt.has_key?('Export') ? {'Name' => opt['Export']} : nil
      self[:Outputs][name] = opt.merge('Value' => value, 'Export' => export).compact
    end
  end
end

module Stax
  class Stack < Base
    class_option :use_previous_value, aliases: '-u', type: :array, default: [], desc: 'params to use previous value'

    no_commands do

      ## backward-compatibility
      def cfer_parameters
        cfn_parameters
      end

      ## override with S3 bucket for upload of large templates as needed
      def cfer_s3_path
        nil
      end

      def cfer_client
        @_cfer_client ||= Cfer::Cfn::Client.new({})
      end

      ## generate JSON for stack without sending to cloudformation
      def cfer_generate(filename)
        Cfer::stack_from_file(filename, client: cfer_client, parameters: stringify_keys(cfn_parameters)).to_json
      rescue Cfer::Util::FileDoesNotExistError => e
        fail_task(e.message)
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