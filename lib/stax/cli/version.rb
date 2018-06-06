require 'stax/version'

module Stax
  class Cli < Base

    desc 'version', 'show version'
    def version
      puts Stax::VERSION
    end

  end
end