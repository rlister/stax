require 'octokit'

module Stax
  class Git < Base
    no_commands do
      def self.branch
        @_branch ||= `git symbolic-ref --short HEAD`.chomp
      end

      def self.sha
        @_sha ||= `git rev-parse HEAD`.chomp
      end

      def self.origin_url
        @_origin_url ||= `git config --get remote.origin.url`.chomp
      end

      ## path like org/repo
      def self.repo
        @_repo ||= GitCloneUrl.parse(origin_url)&.path&.sub(/\.git$/, '')
      end

      def self.origin_sha
        @_origin_sha ||= `git rev-parse origin/#{branch}`.chomp
      end

      def self.toplevel
        @_toplevel ||= `git rev-parse --show-toplevel`.chomp
      end

      def self.uncommitted_changes?
        !`git diff --shortstat`.chomp.empty?
      end

      def self.unpushed_commits?
        sha != origin_sha
      end

      def self.octokit
        abort('Please set GITHUB_TOKEN') unless ENV['GITHUB_TOKEN']
        @_octokit ||= Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
      end

      def self.tags
        @_tags ||= octokit.tags(repo)
      end

      ## tag the sha and push to github
      def self.tag(tag, sha)
        system "git tag #{tag} #{sha} && git push origin #{tag} --quiet"
      end

      ## check if this sha exists in github
      def self.exists?(sha = Git.sha)
        !octokit.commit(repo, sha).nil?
      rescue Octokit::NotFound
        false
      end
    end

    desc 'branch', 'show current git branch'
    def branch
      puts Git.branch
    end

    desc 'sha', 'show current local git sha'
    def sha
      puts Git.sha
    end

    desc 'exists', 'check if sha exists in github'
    def exists(sha = Git.sha)
      debug("Checking #{short_sha(sha)} exists in github")
      puts Git.exists?(sha)
    end
  end

  class Cli < Base
    class_option :branch, type: :string, default: Git.branch, desc: 'git branch to use'

    desc 'git', 'git tasks'
    subcommand 'git', Git
  end
end