require 'octokit'

module Stax
  class Github < Base

    no_commands do
      def self.octokit
        abort('Please set GITHUB_TOKEN') unless ENV['GITHUB_TOKEN']
        @_octokit ||= Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
      end

      def self.tags
        @_tags ||= octokit.tags(Git.repo)
      end

      ## check if this sha exists in github
      def self.exists?
        !octokit.commit(Git.repo, Git.sha).nil?
      rescue Octokit::NotFound
        false
      end
    end

  end
end