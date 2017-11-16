require 'stax/aws/sts'
require 'stax/aws/ecr'

module Stax
  class Docker < Base

    no_commands do
      def docker_registry
        @_docker_registry ||= "#{Aws::Sts.id.account}.dkr.ecr.#{ENV['AWS_REGION']}.amazonaws.com"
      end

      def docker_repository
        @_docker_repository ||= "#{docker_registry}/#{File.basename(Git.toplevel)}"
      end

      ## build a docker image locally
      def docker_local_build
        system "docker build -t #{docker_repository} #{Git.toplevel}"
      end

      ## push docker image from local
      def docker_push
        system "docker push #{docker_repository}"
      end
    end

    desc 'registry', 'show registry'
    def registry
      puts docker_registry
    end

    desc 'repository', 'show repository'
    def repository
      puts docker_repository
    end

    desc 'build', 'build docker image'
    def build
      debug("Docker build #{docker_repository}")
      docker_local_build
    end

    desc 'login', 'login to registry'
    def login
      Aws::Ecr.auth.each do |auth|
        debug("Login to ECR registry #{auth.proxy_endpoint}")
        user, pass = Base64.decode64(auth.authorization_token).split(':')
        system "docker login -u #{user} -p #{pass} #{auth.proxy_endpoint}"
      end
    end

    desc 'push', 'push docker image to registry'
    def push
      debug("Docker push #{docker_repository}")
      docker_push
    end
  end

end