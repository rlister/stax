require 'thor'

module Stax
  class Base < Thor
    no_commands do
      def debug(message)
        say "[DEBUG] #{message}", :blue
      end

      def warn(message)
        say "[WARNING] #{message}", :red
      end

      def fail_task(message, quit = true)
        say "[FAIL] #{message}", :red
        exit(1) if quit
      end

      ## make string safe to use in naming CFN stuff
      def cfn_safe(string)
        string.gsub(/[\W_]/, '-')
      end

      def stack_prefix
        'ops-'
      end
    end
  end
end