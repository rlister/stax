module Stax
  module Generators
    class Base < Thor::Group
      include Thor::Actions

      protected

      ## name for invoking this generator
      def self.command_name
        self.to_s.split('::').last.delete_suffix('Generator').downcase
      end

      ## override help banner to make sense for generators
      def self.banner(*args)
        "#{basename} generate #{command_name} ARGS"
      end

    end
  end
end