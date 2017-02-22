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
        @@_stack_prefix
      end

      def stringify_keys(thing)
        if thing.is_a?(Hash)
          Hash[ thing.map { |k,v| [ k.to_s, stringify_keys(v) ] } ]
        elsif thing.respond_to?(:map)
          thing.map { |v| stringify_keys(v) }
        else
          thing
        end
      end

    end
  end
end