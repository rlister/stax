require 'git_clone_url'

module Stax
  class Git

    def self.branch
      @_branch ||= `git symbolic-ref --short HEAD`.chomp
    end

    def self.sha
      @_sha ||= `git rev-parse HEAD`.chomp
    end

    def self.short_sha
      @_short_sha ||= self.sha.slice(0,7)
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

  end
end