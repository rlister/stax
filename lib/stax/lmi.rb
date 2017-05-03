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

        end

      end
    end
  end
end