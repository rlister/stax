module Stax
  class Cli < Base

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