require 'open-uri'
require 'yaml'
require 'stax/aws/lambda'

module Stax
  module Lambda
    def self.included(thor)
      thor.desc(:lambda, 'Lambda subcommands')
      thor.subcommand(:lambda, Cmd::Lambda)
    end
  end

  module Cmd
    class Lambda < SubCommand

      no_commands do
        def stack_lambdas
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::Lambda::Function')
        end
      end

      desc 'ls', 'list lambdas for stack'
      def ls
        names = stack_lambdas.map(&:physical_resource_id)
        print_table Aws::Lambda.list.select { |l|
          names.include?(l.function_name)
        }.map { |l|
          size = (l.code_size/1.0.megabyte).round.to_s + 'MB'
          [l.function_name, l.description, l.runtime, size, l.last_modified]
        }
      end

      desc 'config ID', 'get function configuration'
      def config(id)
        cfg = Aws::Lambda.configuration(my.resource(id))
        puts YAML.dump(stringify_keys(cfg.to_hash))
      end

      desc 'code ID', 'get code for lambda function with ID'
      method_option :url, type: :boolean, default: false, desc: 'return just URL for code'
      def code(id)
        url = Aws::Lambda.code(my.resource(id))
        if options[:url]
          puts url
        else
          Tempfile.new([my.stack_name, '.zip']).tap do |file|
            file.write(open(url).read)
            file.close
            puts %x[unzip -p #{file.path}] # unzip all contents to stdout
          end
        end
      end

    end
  end

end