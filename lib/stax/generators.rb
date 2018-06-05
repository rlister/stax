require 'stax/generators/base'

module Stax
  module Generators

    def self.load_builtin_generators
      Dir[File.join(__dir__, 'generators', '**', '*_generator.rb')].map(&method(:require))
    end

    ## load any generators in project lib/generators/
    def self.load_local_generators
      if Stax.root_path
        Dir[Stax.root_path.join('lib', 'generators', '**', '*_generator.rb')].map(&method(:require))
      end
    end

    ## find subclass that matches command name
    def self.find(name)
      Base.subclasses.find do |g|
        g.command_name == name
      end
    end

  end
end