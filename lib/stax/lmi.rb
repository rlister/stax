module Stax
  module Lmi
    def self.included(thor)     # magic to make mixins work in Thor
      thor.class_eval do        # ... so magical

        no_commands do
          def lmi_security_group
            @_lmi_security_group ||= cf(:id, [stack_name, :sgssh], quiet: true)
          end

          def let_me_in_allow
            debug("Allowing let-me-in for #{lmi_security_group}")
            system("let-me-in --filter group-id #{lmi_security_group}")
          end

          def let_me_in_revoke
            debug("Revoking let-me-in for #{lmi_security_group}")
            system("let-me-in --filter group-id --revoke #{lmi_security_group}")
          end
        end

        # desc 'ssh [CMD]', 'be a total failure and ssh to instance(s)'
        # method_option :all,       aliases: '-a', type: :boolean, default: false, desc: 'ssh to all instances in ASG'
        # method_option :instances, aliases: '-i', type: :array,   default: nil,   desc: 'list of partial instance IDs to filter'
        # def ssh(*cmds)
        #   let_me_in_allow
        #   auto_scaling_groups.each do |asg|
        #     debug("SSH to instances for #{asg.physical_resource_id}")
        #     asg(:ssh, [asg.physical_resource_id, *cmds], all: options[:all], instances: options[:instances])
        #   end
        # ensure
        #   let_me_in_revoke
        # end

      end
    end
  end
end