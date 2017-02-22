module Stax
  class Cli < Base
    include Awful::Short

    desc 'version', 'show version'
    def version
      puts VERSION
    end

    desc 'ls', 'list stacks for this branch'
    def ls(regex = nil)
      # regex = cfn_safe(options[:branch]) + '(-|$)'
      cf(:ls, [regex || stack_prefix].compact, long: true)
    end
  end
end