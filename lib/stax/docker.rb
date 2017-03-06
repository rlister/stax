require 'awful/ecr'

module Stax
  class Docker < Base
    include Awful::Short

    no_commands do
      ## TODO: look me up if not overridden by user
      def registry
        @_registry ||= 'xxx.dkr.ecr.us-east-1.amazonaws.com'
      end

      def repository
        @_repository ||= "#{registry}/#{File.basename(Git.toplevel)}"
      end
    end

    desc 'build', 'build docker image'
    def build
      debug("Docker build #{repository}")
      system "docker build -t #{repository} #{Git.toplevel}"
    end

    desc 'login', 'login to registry'
    def login
      debug("Login to ECR registry #{registry}")
      ecr(:login)
    end

    desc 'push', 'push docker image to registry'
    def push
      debug("Docker push #{repository}")
      puts "docker push #{repository}"
    end
  end

  class Cli < Base
    desc 'docker', 'docker tasks'
    subcommand 'docker', Docker
  end
end