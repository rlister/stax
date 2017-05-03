require 'awful/security_group'

## let-me-in mixin allows temporary ssh access to a security group
module Stax
  module Lmi
    def self.included(thor)     # magic to make mixins work in Thor
      thor.class_eval do        # ... so magical

        no_commands do

          ## id of security group to allow
          def lmi_security_group
            @_lmi_security_group ||= cf(:id, [stack_name, :sgssh], quiet: true)
          end

          ## allow ingress
          def let_me_in_allow
            debug("Allowing ssh access to #{lmi_security_group}")
            sg(:authorize, [lmi_security_group])
          end

          ## revoke ingress
          def let_me_in_revoke
            debug("Revoking ssh access from #{lmi_security_group}")
            sg(:revoke, [lmi_security_group])
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
end