require 'stax/aws/secrets_manager'

module Stax
  module SecretsManager
    def self.included(thor)
      thor.desc('sm COMMAND', 'SecretsManager subcommands')
      thor.subcommand(:sm, Cmd::SecretsManager)
    end

    ## monkey-patch in your application as needed
    def secrets_manager_prefix
      @_secrets_manager_prefix ||= "#{app_name}/#{branch_name}/"
    end
  end

  module Cmd
    class SecretsManager < SubCommand

      desc 'ls', 'list secrets'
      def ls
        debug("Secrets for #{my.stack_name}")
        print_table Aws::SecretsManager.list.select { |s|
          s.name.start_with?(my.secrets_manager_prefix)
        }.map { |s|
          [s.name, s.description, s.last_accessed_date]
        }.sort
      end

      desc 'get ID', 'get secret'
      def get(id)
        id = my.secrets_manager_prefix + id unless id.include?('/') # allow absolute or relative path
        puts Aws::SecretsManager.get(id).secret_string
      end

    end
  end
end