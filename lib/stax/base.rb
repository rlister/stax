module Stax
  class Base < Thor

    no_commands do
      def app_name
        @_app_name ||= cfn_safe(File.basename(Git.toplevel))
      end

      def stack_prefix
        @_stack_prefix ||= [app_name, branch_name].compact.join('-') + '-'
      end

      ## find or create a stack object
      def stack(id)
        object = Stax.const_get(id.to_s.capitalize)
        ObjectSpace.each_object(object).first || object.new([], options)
      end

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

      def prepend(prefix, id)
        p = prefix.to_s
        id.start_with?(p) ? id : p + id
      end

      def append(suffix, id)
        s = suffix.to_s
        id.end_with?(s) ? id : id + s
      end

      def branch_name
        @_branch_name ||= cfn_safe(options[:branch])
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

      ## psycho version of thor yes?() that demands a y or n answer
      def y_or_n?(statement, color = nil)
        loop do
          case ask(statement, color, :add_to_history => false).downcase
          when 'y'
            return true
          when 'n'
            return false
          else
            puts "please respond 'y' or 'n'"
          end
        end
      end

      def color(string, hash)
        set_color(string, hash.fetch(string.to_sym, :yellow))
      end

    end
  end
end