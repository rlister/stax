module Stax
  class Base < Thor
    @@_stack_prefix = `git symbolic-ref --short HEAD`.chomp + '-'

    def self.load_staxfile
      file = File.join(Dir.pwd, 'Staxfile')
      Stax::Base.class_eval(File.binread(file)) if File.exist?(file)
    end

    ## add a Stack subclass as a thor subcommand
    def self.add_stack(name)
      c = name.capitalize

      ## create the class if it does not exist yet
      klass = self.const_defined?(c) ? self.const_get(c) : self.const_set(c, Class.new(Stack))

      ## create thor subcommand
      Cli.desc(name, "control #{name} stack")
      Cli.subcommand(name, klass)
    end

    def self.set_prefix(prefix)
      @@_stack_prefix = prefix
    end

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
    end
  end
end