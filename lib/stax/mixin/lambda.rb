require 'open-uri'
require 'yaml'
require 'base64'
require 'stax/aws/lambda'

module Stax
  module Lambda
    def self.included(thor)
      thor.desc('lambda COMMAND', 'Lambda subcommands')
      thor.subcommand(:lambda, Cmd::Lambda)
    end
  end

  module Cmd
    class Lambda < SubCommand
      stax_info :ls

      no_commands do
        def stack_lambdas
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::Lambda::Function')
        end

        ## return zip file contents, make it if necessary
        def zip_thing(thing)
          if File.directory?(thing)
            Dir.chdir(thing) do
              %x[zip -q -r - .]      # zip dir contents
            end
          elsif thing.match(/\.zip$/i)
            File.read(thing)         # raw zipfile contents
          elsif File.file?(thing)
            %x[zip -q -j - #{thing}] # zip a single file
          else
            nil
          end
        end
      end

      desc 'ls', 'list lambdas for stack'
      def ls
        debug("Lambda functions for stack #{my.stack_name}")
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

      desc 'update ID FILE', 'update code for lambda function with ID'
      method_option :publish, aliases: '-p', type: :boolean, default: false, desc: 'publish as a new version'
      def update(id, file)
        Aws::Lambda.update_code(
          function_name: my.resource(id),
          publish: options[:publish],
          zip_file: zip_thing(file),
        )&.version.tap do |v|
          puts "version: #{v}"
        end
      end

      desc 'test ID', 'run lambda with ID'
      method_option :type,    type: :string,  default: nil,   desc: 'invocation type: RequestResponse, Event'
      method_option :tail,    type: :boolean, default: nil,   desc: 'tail log for RequestResponse'
      method_option :payload, type: :string,  default: nil,   desc: 'json input to function'
      method_option :file,    type: :string,  default: nil,   desc: 'get json payload from file'
      def test(id)
        Aws::Lambda.invoke(
          function_name: my.resource(id),
          invocation_type: options[:type],
          log_type: options[:tail] ? 'Tail' : nil,
          payload: options[:file] ? File.open(options[:file]) : options[:payload],
        ).tap do |resp|
          puts resp.status_code
          warn(resp.function_error) if resp.function_error
          puts Base64.decode64(resp.log_result) if options[:tail]
        end
      end

    end
  end
end
