require 'stax/generators'

module Stax
  class Cli < Base

    desc 'generate NAME [ARGS]', 'run code generators'
    def generate(name = nil, *args)
      Stax::Generators.load_builtin_generators
      Stax::Generators.load_local_generators

      if name.nil?
        Stax::Generators::Base.subclasses.each do |g|
          say_status(g.command_name, g.desc, :bold)
        end
      else
        klass = Stax::Generators.find(name)
        fail_task("Unknown generator #{name}") unless klass
        klass.start(args)
      end
    end

  end
end