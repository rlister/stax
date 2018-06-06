module Stax
  class Cli < Base

    no_commands do
      def ls_staxfile_stacks
        print_table Stax.stack_list.map { |id|
          name = stack(id).stack_name
          if (s = Aws::Cfn.describe(name))
            [s.stack_name, s.creation_time, color(s.stack_status, Aws::Cfn::COLORS), s.description]
          else
            options[:existing] ? nil : [name, '-']
          end
        }.compact
      end

      def ls_stacks_with_prefix(prefix)
        print_table Aws::Cfn.stacks.select { |s|
          s.stack_name.start_with?(prefix || stack_prefix)
        }.map { |s|
          [s.stack_name, s.creation_time, color(s.stack_status, Aws::Cfn::COLORS), s.template_description]
        }.sort
      end

      def ls_account_stacks
        print_table Aws::Cfn.stacks.map { |s|
          [s.stack_name, s.creation_time, color(s.stack_status, Aws::Cfn::COLORS), s.template_description]
        }.sort
      end
    end

    desc 'ls [PREFIX]', 'list stacks'
    method_option :existing, aliases: '-e', type: :boolean, default: false, desc: 'list just existing stacks'
    method_option :all,      aliases: '-a', type: :boolean, default: false, desc: 'list all running stacks with our prefix'
    method_option :account,  aliases: '-A', type: :boolean, default: false, desc: 'list all running stacks in account'
    def ls(prefix = nil)
      if options[:account]
        ls_account_stacks
      elsif options[:all]
        ls_stacks_with_prefix(prefix)
      else
        ls_staxfile_stacks
      end
    end

  end
end