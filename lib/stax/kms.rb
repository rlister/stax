require 'awful/kms'

module Stax
  module Kms
    def self.included(thor)
      thor.class_eval do

        no_commands do
          def kms_id
            @_kms_id ||= cf(:id, [stack_name, :kmskey], quiet: true)
          end
        end

        desc 'kms', 'get KMS key id'
        def kms
          debug("KMS ID for stack #{stack_name}")
          puts kms_id
        end

      end
    end
  end
end