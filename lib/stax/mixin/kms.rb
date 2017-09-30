require 'stax/aws/kms'

module Stax
  module Kms
    def self.included(thor)
      thor.desc(:kms, 'KMS subcommands')
      thor.subcommand(:kms, Cmd::Kms)
    end
  end

  module Cmd
    class Kms < SubCommand

      no_commands do
        def stack_kms_keys
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::KMS::Key')
        end
      end

      desc 'ls', 'list kms keys for stack'
      def ls
        print_table stack_kms_keys.map { |r|
          k = Aws::Kms.describe(r.physical_resource_id)
          [k.key_id, k.key_state, k.creation_date, k.description]
        }
      end

    end
  end
end