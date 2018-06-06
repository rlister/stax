## Monkey-patches you may make to change stack behavior.
## Changing these here will affect all stacks.
## You may also define these per-stack in the sub-class for each stack in lib/stacks/.

module Stax
  class Stack < Base

    no_commands do

      ## your application name, will start all stack names
      # def app_name
      #   @_app_name ||= options[:app].empty? ? nil : cfn_safe(options[:app])
      # end

      ## git branch to insert in stack names
      # def branch_name
      #   @_branch_name ||= cfn_safe(options[:branch])
      # end

      ## format of stack names like $app-$branch-$stack
      # def stack_prefix
      #   @_stack_prefix ||= [app_name, branch_name].compact.join('-') + '-'
      # end

      ## turn on stack protection when creating stack
      # def cfn_termination_protection
      #   false
      # end

      ## enforce changesets for stack update
      # def stack_force_changeset
      #   false
      # end

    end

  end
end
