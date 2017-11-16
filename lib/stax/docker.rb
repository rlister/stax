require 'stax/aws/ecr'

module Stax
  class Docker < Base

    no_commands do
      ## TODO: look me up if not overridden by user
      def registry
        @_registry ||= 'xxx.dkr.ecr.us-east-1.amazonaws.com'
        @_docker_registry ||= "#{Aws::Sts.id.account}.dkr.ecr.#{ENV['AWS_REGION']}.amazonaws.com"
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
      Aws::Ecr.auth.each do |auth|
        debug("Login to ECR registry #{auth.proxy_endpoint}")
        user, pass = Base64.decode64(auth.authorization_token).split(':')
        system "docker login -u #{user} -p #{pass} #{auth.proxy_endpoint}"
      end
    end

    desc 'push', 'push docker image to registry'
    def push
      debug("Docker push #{repository}")
      system "docker push #{repository}"
    end
  end

end