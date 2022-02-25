require 'stax/cli/version'
require 'stax/cli/ls'
require 'stax/cli/new'
require 'stax/cli/generate'
require 'stax/cli/crud'
require 'stax/cli/info'

module Stax
  class Cli < Base
    class_option :branch, type: :string, default: Git.branch, desc: 'git branch to use'
    class_option :app,    type: :string, default: File.basename(Git.toplevel), desc: 'application name'

    ## silence deprecation warning
    ## https://github.com/erikhuda/thor/blob/fb625b223465692a9d8a88cc2a483e126f1a8978/CHANGELOG.md#100
    def self.exit_on_failure?
      true
    end

  end
end
