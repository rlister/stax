require 'aws-sdk-codebuild'

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

        def builds(ids)
          client.batch_get_builds(ids: ids).builds
        end

        def reports(arns)
          client.batch_get_reports(report_arns: arns).reports
        end

        ## TODO: this fails attempt to page as enumerable, check back with sdk v3
        def tests(arn)
          client.describe_test_cases(report_arn: arn).test_cases
        end

        def start(opt)
          client.start_build(opt).build
        end

      end

    end
  end
end
