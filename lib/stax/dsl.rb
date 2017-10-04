## Staxfile DSL commands
module Stax
  module Dsl
    def stack(*args)
      Stax.add_stack(*args)
    end

    def command(*args)
      Stax.add_command(*args)
    end
  end
end

## add main object singleton methods
extend Stax::Dsl