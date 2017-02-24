module Stax
  class Cli < Base
    include Awful::Short

    no_commands do
      def stack_prefix
        @_stack_prefix ||= cfn_safe(options[:branch] + '-')
      end
    end

    desc 'version', 'show version'
    def version
      puts VERSION
    end

    desc 'ls', 'list stacks for this branch'
    def ls(regex = nil)
      cf(:ls, [regex || stack_prefix].compact, long: true)
    end
  end
end