module Stax
  module Aws
    class Codebuild < Sdk

      class << self

        def client
          @_client ||= ::Aws::CodeBuild::Client.new
        end

        def projects(names)
          client.batch_get_projects(names: names).projects
        end

        ## returns ids of num most recent builds for project
        def builds_for_project(name, num = 100)
          count = 0
          next_token = nil
          builds = []
          loop do
            r = client.list_builds_for_project(project_name: name, next_token: next_token)
            builds += r.ids
            break if (count += r.ids.count) >= num
            break if (next_token = r.next_token).nil?
          end
          builds.first(num)
        end

        ## return details of num most recent builds
        def builds(name, num = 100)
          client.batch_get_builds(ids: builds_for_project(name, num)).builds
        end

      end

    end
  end
end