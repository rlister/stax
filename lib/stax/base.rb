module Stax
  class Base < Thor

    no_commands do
      def app_name
        @_app_name ||= options[:app].empty? ? nil : cfn_safe(options[:app])
      end

      def branch_name
        @_branch_name ||= cfn_safe(options[:branch])
      end

      def stack_prefix
        @_stack_prefix ||= [app_name, branch_name].compact.join('-') + '-'
      end

      ## find or create a stack object
      def stack(id)
        object = Stax.const_get(id.to_s.capitalize)
        ObjectSpace.each_object(object).first || object.new([], options)
      end

      def ensure_stack(*stacks)
        stacks.each do |s|
          stack(s)&.exists? or fail_task("#{s} stack is required")
        end
      end

      ## alias for stack to preserve semantics
      def command(id)
        stack(id)
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

      ## return true only if all given env vars are set
      def env_set?(*vars)
        vars.map{ |v| ENV.has_key?(v) }.all?
      end

      ## fail unless given env vars are set
      def ensure_env(*vars)
        unless env_set?(*vars)
          fail_task("Please set env: #{vars.join(' ')}")
        end
      end

      def color(string, hash)
        set_color(string, hash.fetch(string.to_sym, :yellow))
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

      ## make epoch human-readable
      def human_time(timestamp)
        timestamp.nil? ? '-' : Time.at(timestamp.to_i/1000)
      end

      ## convert bytes to nearest unit
      def human_bytes(bytes, precision = 0)
        return 0.to_s if bytes < 1
        {T: 1000*1000*1000*1000, G: 1000*1000*1000, M: 1000*1000, K: 1000, B: 1}.each do |unit, value|
          return "#{(bytes.to_f/value).round(precision)}#{unit}" if bytes >= value
        end
      end

    end
  end
end