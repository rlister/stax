require 'stax/aws/sts'
require 'stax/aws/ecr'

module Stax
  class Docker < Base

    no_commands do
      ## default to ECR registry for this account
      def docker_registry
        @_docker_registry ||= "#{Aws::Sts.id.account}.dkr.ecr.#{ENV['AWS_REGION']}.amazonaws.com"
      end

      ## name the docker repo after the git repo
      def docker_repository
        @_docker_repository ||= "#{docker_registry}/#{File.basename(Git.toplevel)}"
      ## full image name for docker push
      end

      ## build a docker image locally
      def docker_local_build
        debug("Docker build #{docker_repository}")
        system "docker build -t #{docker_repository} #{Git.toplevel}"
      end

      ## push docker image from local
      def docker_push
        debug("Docker push #{docker_repository}")
        system "docker push #{docker_repository}"
      end

      ## override this for your argus setup
      def docker_argus_queue
        @_docker_argus_queue ||= Aws::Sqs.queue_url('argus.fifo')
      end

      def docker_argus_build
        debug("Sending to argus #{Git.branch}:#{Git.sha}")
        org, repo = Git.repo.split('/')
        Aws::Sqs.send(
          queue_url: docker_argus_queue,
          message_group_id: repo,
          message_body: {
            org:    org,
            repo:   repo,
            branch: Git.branch,
            sha:    Git.sha,
          }.to_json
        ).tap do |r|
          puts r&.message_id
        end
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
      ## override this method with the desired builder
      docker_local_build
      # docker_argus_build
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
      docker_push
    end

  end
end