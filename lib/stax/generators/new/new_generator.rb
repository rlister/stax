module Stax
  module Generators
    class NewGenerator < Base
      desc 'Create new stax project in give dir.'

      source_root File.expand_path('templates', __dir__)

      def check_args
        usage! if args.size != 1
      end

      def create_stax_dir
        empty_directory(args.first)
        self.destination_root = args.first
      end

      def create_staxfile
        template('Staxfile')
      end

      def create_gemfile
        template('Gemfile')
      end

      def create_dirs
        empty_directory(File.join('lib', 'stack'))
        empty_directory('cf')
      end

      def create_lib_stack
        template(File.join('lib', 'stack.rb'))
      end

      private

      def self.banner(*args)
        "#{basename} generate #{command_name} DIR"
      end

    end
  end
end