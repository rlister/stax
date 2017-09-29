require 'stax/aws/cfn'

module Stax
  class Cli < Base
    include Aws

    desc 'version', 'show version'
    def version
      puts VERSION
    end

    desc 'ls', 'list stacks for this branch'
    def ls
      print_table Cfn.stacks.select { |s|
        s.stack_name.start_with?(branch_name)
      }.map { |s|
        [s.stack_name, s.creation_time, color(s.stack_status, Cfn::COLORS), s.template_description]
      }
    end

  end
end