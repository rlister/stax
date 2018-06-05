require 'stax/generators/base'

## require builtin generators
Dir[File.join(__dir__, 'generators', '**', '*_generator.rb')].map(&method(:require))

module Stax
  module Generators

    ## find subclass that matches command name
    def self.find(name)
      Base.subclasses.find do |g|
        g.command_name == name
      end
    end

  end
end