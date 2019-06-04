## Staxfile DSL commands
module Stax
  module Dsl
    def stack(name, opt = {})
      opt = {groups: @groups}.merge(opt) # merge with defaults
      Stax.add_stack(name, opt)
    end

    def command(*args)
      Stax.add_command(*args)
    end

    ## temporarily change default list of groups
    def group(*groups, &block)
      @groups = groups
      yield
      @groups = nil
    end
  end
end

## add main object singleton methods
extend Stax::Dsl