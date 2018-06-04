require 'stax/generators/base'
module Stax
  module Generators

    def self.invoke(name, *args)
      Stax::Generators::const_get(name.capitalize + 'Generator').start(args)
    end

  end
end