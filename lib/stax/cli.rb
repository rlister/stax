require 'stax/aws/cfn'

module Stax
  class Cli < Base
    include Aws

    COLORS = {
      CREATE_COMPLETE:      :green,
      DELETE_COMPLETE:      :green,
      UPDATE_COMPLETE:      :green,
      CREATE_FAILED:        :red,
      DELETE_FAILED:        :red,
      UPDATE_FAILED:        :red,
      ROLLBACK_IN_PROGRESS: :red,
      ROLLBACK_COMPLETE:    :red,
    }

    desc 'version', 'show version'
    def version
      puts VERSION
    end

    desc 'ls', 'list stacks for this branch'
    def ls
      print_table Cfn.stacks.select { |s|
        s.stack_name.start_with?(stack_prefix)
      }.map { |s|
        [s.stack_name, s.creation_time, color(s.stack_status, COLORS), s.template_description]
      }
    end

  end
end