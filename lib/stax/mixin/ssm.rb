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

    end
  end

end