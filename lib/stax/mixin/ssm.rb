require 'yaml'
require 'stax/aws/ssm'

module Stax
  module Ssm
    def self.included(thor)
      thor.desc(:ssm, 'SSM subcommands')
      thor.subcommand(:ssm, Cmd::Ssm)
    end
  end

  module Cmd
    class Ssm < SubCommand

      COLORS = {
        Online:         :green,
        ConnectionLost: :red,
      }

      no_commands do
        def ssm_parameter_path
          @_ssm_parameter_path ||= prepend('/', [app_name, branch_name, my.class_name].join('/'))
        end
      end

      desc 'instances', 'SSM instance agent information'
      def instances
        print_table Aws::Ssm.instances(my.stack_name).map { |i|
          agent = set_color(i.agent_version, i.is_latest_version ? :green : :yellow)
          [i.instance_id, color(i.ping_status, COLORS), i.last_ping_date_time, agent]
        }
      end

      desc 'shellscript CMD', 'SSM run shell command'
      def shellscript(*cmd)
        opt = {
          document_name: 'AWS-RunShellScript',
          targets: [{key: 'tag:aws:cloudformation:stack-name', values: [my.stack_name]}],
          parameters: {commands: cmd}
        }
        Aws::Ssm.run(opt).tap do |i|
          puts YAML.dump(stringify_keys(i.to_hash))
        end
      end

      desc 'commands', 'list SSM commands'
      def commands
        print_table Aws::Ssm.commands.map { |c|
          [
            c.command_id,
            c.document_name,
            color(c.status, COLORS),
            c.requested_date_time,
            c.comment
          ]
        }
      end

      desc 'invocation', 'SSM invocation details'
      def invocation(id)
        Aws::Ssm.invocation(id).each do |i|
          puts YAML.dump(stringify_keys(i.to_hash))
        end
      end

      desc 'parameters [PATH]', 'list parameters'
      method_option :decrypt, aliases: '-d', type: :boolean, default: false, desc: 'decrypt and show values'
      method_option :recurse, aliases: '-r', type: :boolean, default: false, desc: 'recurse path hierarchy'
      def parameters(path = ssm_parameter_path)
        fields = %i[name type]
        fields << :value if options[:decrypt]
        print_table Aws::Ssm.parameters(
          path: path,
          with_decryption: options[:decrypt],
          recursive: options[:recurse],
        ).map { |p| fields.map{ |f| p.send(f) } }
      end

      desc 'get NAMES', 'get parameters'
      def get(*names)
        paths = names.map { |n| "#{ssm_parameter_path}/#{n}" }
        puts Aws::Ssm.get(names: paths, with_decryption: true).map(&:value)
      end

      desc 'put NAME VALUE', 'put parameter'
      method_option :type,                     type: :string,  default: :SecureString, desc: 'type of value'
      method_option :key,                      type: :string,  default: nil,           desc: 'kms key'
      method_option :overwrite, aliases: '-o', type: :boolean, default: false,         desc: 'overwrite existing'
      def put(name, value)
        Aws::Ssm.put(
          name: [ssm_parameter_path, name].join('/'),
          value: value,
          type: options[:type],
          key_id: options[:key],
          overwrite: options[:overwrite],
        )
      rescue ::Aws::SSM::Errors::ParameterAlreadyExists => e
        warn(e.message)
      end

      desc 'delete NAMES', 'delete parameters'
      def delete(*names)
        paths = names.map { |n| "#{ssm_parameter_path}/#{n}" }
        puts Aws::Ssm.delete(names: paths)
      end

    end
  end

end