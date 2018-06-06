module Stax
  module Generators
    class NewGenerator < Base
      desc 'Create new stax project in give dir.'

      source_root File.expand_path('templates', __dir__)

      def check_args
        usage! if args.size != 1
      end

      def create_stax_dir
        empty_directory(stax_dir)
      end

      def create_staxfile
        create_file(stax_dir.join('Staxfile'))
      end

      def create_gemfile
        template('Gemfile', stax_dir.join('Gemfile'))
      end

      def create_dirs
        empty_directory(stax_dir.join('lib', 'stack'))
        empty_directory(stax_dir.join('cf'))
      end

      private

      def self.banner(*args)
        "#{basename} generate #{command_name} DIR"
      end

      def stax_dir
        @_stax_dir ||= Pathname.new(args.first)
      end

    end
  end
end