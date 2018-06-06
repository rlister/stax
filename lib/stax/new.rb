module Stax
  class Cli < Base

    desc 'new DIR', 'create new stax project in dir'
    def new(dir)
      Stax::Generators.load_builtin_generators
      Stax::Generators::NewGenerator.start(Array(dir))
    end

  end
end