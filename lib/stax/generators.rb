require 'stax/generators/base'

## require builtin generators
Dir[File.join(__dir__, 'generators', '**', '*_generator.rb')].map(&method(:require))

module Stax
  module Generators

    def self.invoke(name, *args)
      const_get(name.capitalize + 'Generator').start(args)
    end

  end
end