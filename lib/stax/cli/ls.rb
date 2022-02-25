module Stax
  class Cli < Base

    no_commands do
      ## fields to show in output
      def ls_stack_fields(s)
        [ s.stack_name, s.creation_time, color(s.stack_status, Aws::Cfn::COLORS) ]
      end

      ## list stacks from Staxfile in given order
      def ls_staxfile_stacks
        print_table Stax.stack_list.map { |id|
          name = stack(id).stack_name
          if (s = Aws::Cfn.describe(name))
            ls_stack_fields(s)
          else
            [ name, '-' ]
          end
        }
      end

      ## list all extant stacks we think match our prefix
      def ls_stacks_with_prefix(prefix)
        print_table Aws::Cfn.stacks.select { |s|
          s.stack_name.start_with?(prefix || stack_prefix)
        }.map { |s|
          ls_stack_fields(s)
        }.sort
      end

      ## list all stacks in account
      def ls_account_stacks
        print_table Aws::Cfn.stacks.map { |s|
          ls_stack_fields(s)
        }.sort
      end
    end

    desc 'ls [PREFIX]', 'list stacks'
    method_option :all,     aliases: '-a', type: :boolean, default: false, desc: 'list all running stacks with our prefix'
    method_option :account, aliases: '-A', type: :boolean, default: false, desc: 'list all running stacks in account'
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
