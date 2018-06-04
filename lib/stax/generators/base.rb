module Stax
  module Generators
    class Base < Thor::Group
      include Thor::Actions

      protected

      def self.subclasses
        ObjectSpace.each_object(singleton_class).map do |klass|
          klass == self ? nil : klass
        end.compact
      end

      ## name for invoking this generator
      def self.command_name
        self.to_s.split('::').last.delete_suffix('Generator').downcase
      end

      def self.invoke(name, args = ARGV)
      end

      ## override help banner to make sense for generators
      def self.banner(*args)
        "#{basename} generate #{command_name} ARGS"
      end

    end
  end
end