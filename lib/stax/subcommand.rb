module Stax
  class SubCommand < Base
    no_commands do

      ## return the Stack instance that called this subcommand
      def my
        @_my ||= stack(current_command_chain.first)
      end

    end
  end
end