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
      stax_info :builds

      COLORS = {
        SUCCEEDED:    :green,
        FAILED:       :red,
        FAULT:        :red,
        CLIENT_ERROR: :red,
        STOPPED:      :red,
      }

      no_commands do
        def print_phase(p)
          duration = (d = p.duration_in_seconds) ? "#{d}s" : ''
          status = p.phase_status || (p.phase_type == 'COMPLETED' ? '' : 'in progress')
          puts "%-16s  %-12s  %4s  %s" % [p.phase_type, color(status, COLORS), duration, p.end_time]
        end

        ## latest run id for a build project
        def latest_run(name)
          Aws::Codebuild.builds_for_project(name, 1).first
        end

        ## aws console link to latest project run
        def latest_run_link(name)
          id = latest_run(name)
          "https://console.aws.amazon.com/codesuite/codebuild/#{aws_account_id}/projects/#{name}/build/#{id}/?region=#{aws_region}"
        end
      end

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
          ids = Aws::Codebuild.builds_for_project(project, options[:number])
          print_table Aws::Codebuild.builds(ids).map { |b|
            duration = human_time_diff(b.end_time - b.start_time)
            [b.id, b.initiator, color(b.build_status, COLORS), duration, b.end_time]
          }
        end
      end

      desc 'phases [ID]', 'show build phases for given or most recent build'
      def phases(id = nil)
        id ||= Aws::Codebuild.builds_for_project(my.stack_project_names.first, 1).first
        debug("Phases for build #{id}")
        Aws::Codebuild.builds([id]).first.phases.each(&method(:print_phase))
      end

      desc 'reports [ID]', 'show reports for given or most recent build'
      def reports(id = nil)
        id ||= Aws::Codebuild.builds_for_project(my.stack_project_names.first, 1).first
        debug("Reports for build #{id}")
        report_arns = Aws::Codebuild.builds([id]).first.report_arns
        print_table Aws::Codebuild.reports(report_arns).map { |r|
          duration = (r.test_summary.duration_in_nano_seconds/1_000_000_000.0).to_s + 's'
          [ r.name, color(r.status, COLORS), duration, r.created ]
        }
      end

      desc 'tests [ID]', 'show test results for given or most recent build'
      def tests(id = nil)
        id ||= Aws::Codebuild.builds_for_project(my.stack_project_names.first, 1).first
        Aws::Codebuild.builds([id]).first.report_arns.each do |report_arn|
          debug("Tests for report #{report_arn}")
          print_table Aws::Codebuild.tests(report_arn).map { |t|
            duration = (t.duration_in_nano_seconds/1_000_000).to_s + 'ms'
            [ t.name, color(t.status, COLORS), t.prefix, t.message, duration ]
          }
        end
      end

      desc 'tail [ID]', 'tail build phases for build'
      def tail(id = nil)
        trap('SIGINT', 'EXIT')    # clean exit with ctrl-c
        id ||= Aws::Codebuild.builds_for_project(my.stack_project_names.first, 1).first
        debug("Phases for build #{id}")
        seen = {}
        loop do
          (Aws::Codebuild.builds([id]).first.phases || []).each do |p|
            i = p.phase_type + p.phase_status.to_s
            print_phase(p) unless seen[i]
            seen[i] = true
          end
          break if seen['COMPLETED']
          sleep(3)
        end
      end

      desc 'start', 'start a build'
      method_option :project, type: :string, default: nil, desc: 'project to build'
      method_option :version, type: :string, default: nil, desc: 'source version to build (sha/branch/tag)'
      def start
        project = options[:project] || my.stack_project_names.first
        version = options[:version] || Git.sha
        debug("Starting build for #{project} #{version}")
        build = Aws::Codebuild.start(
          project_name: project,
          source_version: version,
        )
        puts build.id
        tail build.id
      end

      desc 'link', 'link to latest run for builds'
      def link
        my.stack_project_names.map do |name|
          puts latest_run_link(name)
        end
      end

      desc 'open', 'open latest run in aws console'
      def open
        my.stack_project_names.map do |name|
          os_open(latest_run_link(name))
        end
      end

    end
  end
end
