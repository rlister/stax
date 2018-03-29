require 'stax/aws/codebuild'

module Stax
  module Codebuild
    def self.included(thor)
      thor.desc(:codebuild, 'Codebuild subcommands')
      thor.subcommand(:codebuild, Cmd::Codebuild)
    end

    def stack_projects
      @_stack_projects ||= Aws::Cfn.resources_by_type(stack_name, 'AWS::CodeBuild::Project')
    end

    def stack_project_names
      @_stack_project_names ||= stack_projects.map(&:physical_resource_id)
    end
  end

  module Cmd
    class Codebuild < SubCommand
      COLORS = {
        SUCCEEDED: :green,
        FAILED:    :red,
      }

      desc 'projects', 'list projects'
      def projects
        print_table Aws::Codebuild.projects(my.stack_project_names).map { |p|
          [p.name, p.source.location, p.environment.image, p.environment.compute_type, p.last_modified]
        }
      end

      desc 'builds', 'list builds for stack projects'
      method_option :number, aliases: '-n', type: :numeric, default: 10, desc: 'number of builds to list'
      def builds
        my.stack_project_names.each do |project|
          debug("Builds for #{project}")
          print_table Aws::Codebuild.builds(project, options[:number]).map { |b|
            duration = human_time_diff(b.end_time - b.start_time)
            [b.id, b.initiator, color(b.build_status, COLORS), duration, b.end_time]
          }
        end
      end

    end
  end
end