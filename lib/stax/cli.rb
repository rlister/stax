require 'stax/aws/cfn'

module Stax
  class Cli < Base
    class_option :branch, type: :string, default: Git.branch, desc: 'git branch to use'
    class_option :app,    type: :string, default: File.basename(Git.toplevel), desc: 'application name'

    desc 'version', 'show version'
    def version
      puts VERSION
    end

    desc 'ls', 'list stacks for this branch'
    def ls
      print_table Aws::Cfn.stacks.select { |s|
        s.stack_name.start_with?(stack_prefix)
      }.map { |s|
        [s.stack_name, s.creation_time, color(s.stack_status, Aws::Cfn::COLORS), s.template_description]
      }.sort
    end

  end
end