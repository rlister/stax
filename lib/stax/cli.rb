require 'stax/cli/version'
require 'stax/cli/ls'
require 'stax/cli/new'
require 'stax/cli/generate'
require 'stax/cli/crud'

module Stax
  class Cli < Base
    class_option :branch, type: :string, default: Git.branch, desc: 'git branch to use'
    class_option :app,    type: :string, default: File.basename(Git.toplevel), desc: 'application name'
  end
end