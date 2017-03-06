require 'awful/ssm'

module Stax
  module Ssm
    def self.included(thor)
      thor.class_eval do

        no_commands do
          ## run array of commands on asg instances
          def ssm_run_commands(*commands)
            ids = auto_scaling_instances.map(&:instance_id)
            debug("Running SSM on #{ids.join(',')}")
            Awful::Ssm.new.invoke(:shell_script, ids, commands: commands)
          end
        end

        desc 'ssm CMD', 'run CMD on all instances via SSM'
        def ssm(*cmd)
          ssm_run_commands(cmd.join(' '))
        end

      end
    end
  end
end