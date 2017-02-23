require 'octokit'

module Stax
  class Git < Base
    no_commands do
      def self.branch
        @branch ||= `git symbolic-ref --short HEAD`.chomp
      end

      def self.sha
        @sha ||= `git rev-parse HEAD`.chomp
      end

      def self.origin_sha
        @origin_sha ||= `git rev-parse origin/#{branch}`.chomp
      end

      def self.toplevel
        @toplevel ||= `git rev-parse --show-toplevel`.chomp
      end

      def self.uncommitted_changes?
        !`git diff --shortstat`.chomp.empty?
      end

      def self.unpushed_commits?
        sha != origin_sha
      end

      def self.octokit
        abort('Please set GITHUB_TOKEN') unless ENV['GITHUB_TOKEN']
        @octokit ||= Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
      end

      def self.tags
        @tags ||= octokit.tags('woodmont/spreeworks')
      end

      ## tag the sha and push to github
      def self.tag(tag, sha)
        system "git tag #{tag} #{sha} && git push origin #{tag} --quiet"
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
  end

  class Cli < Base
    class_option :branch, type: :string, default: Git.branch, desc: 'Git branch to use'

    desc 'git', 'git tasks'
    subcommand 'git', Git
  end
end