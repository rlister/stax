module Stax
  module Generators
    class GeneratorGenerator < Base
      desc 'Create new generator with given name.'

      source_root File.expand_path('templates', __dir__)

      def check_args
        usage! if args.size != 1
      end

      def create_generator_file
        template('generator.rb.erb', File.join(generator_path, generator_name + '_generator.rb'))
      end

      def create_templates_dir
        create_file File.join(generator_path, 'templates', '.empty_directory')
      end

      private

      def self.banner(*args)
        "#{basename} generate #{command_name} NAME"
      end

      def generator_name
        @_generator_name ||= args.first.underscore
      end

      def class_name
        @_class_name ||= args.first.camelize + 'Generator'
      end

      def generator_path
        @_generator_path ||= File.join([Stax.root_path, 'lib', 'generators', args.first.underscore].compact)
      end

    end
  end
end