require 'stax/aws/ecr'

module Stax
  class Docker < Base

    no_commands do
      ## default to ECR registry for this account
      def docker_registry
        @_docker_registry ||= "#{aws_account_id}.dkr.ecr.#{aws_region}.amazonaws.com"
      end

      ## name the docker repo after the git repo
      def docker_repository
        @_docker_repository ||= File.basename(Git.toplevel)
      end

      ## full image name for docker push
      def docker_image
        @_docker_image ||= "#{docker_registry}/#{docker_repository}"
      end

      ## build a docker image locally
      def docker_build
        debug("Docker build #{docker_image}")
        system "docker build -t #{docker_image} #{Git.toplevel}"
      end

      ## push docker image from local
      def docker_push
        debug("Docker push #{docker_image}")
        system "docker push #{docker_image}"
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

    desc 'registry', 'show registry name'
    def registry
      puts docker_registry
    end

    desc 'repository', 'show repository name'
    def repository
      puts docker_repository
    end

    desc 'image', 'show image name'
    def image
      puts docker_image
    end

    ## override this method with the desired builder
    desc 'build', 'build docker image'
    def build
      docker_build
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

    desc 'exists', 'check if docker image exists in ECR'
    def exists
      puts Aws::Ecr.exists?(docker_repository, Git.sha)
    end

    desc 'poll', 'poll ECR until docker image exists'
    def poll
      debug("Waiting for image in ECR #{docker_repository}:#{Git.sha}")
      sleep 10 until Aws::Ecr.exists?(docker_repository, Git.sha)
    end

  end
end