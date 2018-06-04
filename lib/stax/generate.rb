module Stax
  class Cli < Base

    desc 'generate NAME [ARGS]', 'run code generators'
    def generate(generator, *args)
      Stax::Generators.invoke(generator, *args)
    rescue NameError => e
      fail_task(e.message)
    end

  end
end