require 'stax/aws/keypair'

module Stax
  module Keypair
    def self.included(thor)
      thor.desc(:keypair, 'Keypair subcommands')
      thor.subcommand(:keypair, Cmd::Keypair)
    end
  end

  module Cmd
    class Keypair < SubCommand

      desc 'ls', 'list keypairs'
      method_option :all_keys, aliases: '-a', type: :boolean, default: false, desc: 'list all keys'
      def ls
        names = options[:all_keys] ? nil : [my.stack_name]
        print_table Aws::Keypair.describe(names).map { |k|
          [k.key_name, k.key_fingerprint]
        }
      end

      desc 'create [NAME]', 'create keypair'
      def create(name = my.stack_name)
        puts Aws::Keypair.create(name).key_material
      end

      desc 'delete [NAME]', 'delete keypair'
      def delete(name = my.stack_name)
        Aws::Keypair.delete(name)
      end

    end
  end
end