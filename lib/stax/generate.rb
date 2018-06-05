require 'stax/generators'

module Stax
  class Cli < Base

    desc 'generate NAME [ARGS]', 'run code generators'
    def generate(name = nil, *args)
      if name.nil?
        Stax::Generators::Base.subclasses.each do |g|
          say_status(g.command_name, g.desc, :bold)
        end
      else
        Stax::Generators.invoke(name, *args)
      end
    rescue NameError => e
      fail_task(e.message)
    end

  end
end