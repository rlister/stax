module Stax

  module Cmd
    class Git < Base

      desc 'branch', 'show current git branch'
      def branch
        puts Stax::Git.branch
      end

      desc 'sha', 'show current local git sha'
      def sha
        puts Stax::Git.sha
      end

    end

  end
end