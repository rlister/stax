require 'stax/aws/codepipeline'

module Stax
  module Codepipeline
    def self.included(thor)
      thor.desc(:codepipeline, 'Codepipeline subcommands')
      thor.subcommand(:codepipeline, Cmd::Codepipeline)
    end

    def stack_pipelines
      @_stack_pipelines ||= Aws::Cfn.resources_by_type(stack_name, 'AWS::CodePipeline::Pipeline')
    end

    def stack_pipeline_names
      @_stack_pipeline_names ||= stack_pipelines.map(&:physical_resource_id)
    end
  end

  module Cmd
    class Codepipeline < SubCommand
      COLORS = {
        Succeeded: :green,
        Failed:    :red,
      }

      desc 'stages', 'list pipeline stages'
      def stages
        my.stack_pipeline_names.each do |name|
          debug("Stages for #{name}")
          print_table Aws::Codepipeline.stages(name).map { |s|
            actions = s.actions.map{ |a| a&.action_type_id&.provider }.join(' ')
            [s.name, actions]
          }
        end
      end

      desc 'history', 'pipeline execution history'
      method_option :number, aliases: '-n', type: :numeric, default: 10, desc: 'number of items'
      def history
        my.stack_pipeline_names.each do |name|
          debug("Execution history for #{name}")
          print_table Aws::Codepipeline.executions(name, options[:number]).map { |e|
            r = Aws::Codepipeline.execution(name, e.pipeline_execution_id)&.artifact_revisions&.first
            age = human_time_diff(Time.now - e.last_update_time, 1)
            duration = human_time_diff(e.last_update_time - e.start_time)
            [e.pipeline_execution_id, color(e.status, COLORS), "#{age} ago", duration, r&.revision_id&.slice(0,7) + ':' + r&.revision_summary]
          }
        end
      end

      desc 'state', 'pipeline state'
      def state
        require 'pp'
        my.stack_pipeline_names.each do |name|
          state = Aws::Codepipeline.state(name)
          debug("State for #{name} at #{state.updated}")
          print_table state.stage_states.map { |s|
            s.action_states.map { |a|
              l = a.latest_execution
              percent = (l.percent_complete || 100).to_s + '%'
              sha = a.current_revision&.revision_id&.slice(0,7)
              ago = human_time_diff(Time.now - l.last_status_change, 1)
              [s.stage_name, a.action_name, color(l.status, COLORS), percent, "#{ago} ago", sha, l.error_details&.message]
            }
          }.flatten(1)
        end
      end

      desc 'start [NAME]', 'start execution for pipeline'
      def start(name = nil)
        name ||= my.stack_pipeline_names.first
        debug("Starting execution for #{name}")
        puts Aws::Codepipeline.start(name)
        tail name
      end

      desc 'tail [NAME]', 'tail pipeline state changes'
      def tail(name = nil)
        trap('SIGINT', 'EXIT')    # clean exit with ctrl-c
        name ||= my.stack_pipeline_names.first
        last_seen = nil
        loop do
          state = Aws::Codepipeline.state(name)
          now = Time.now
          stages = state.stage_states.map do |s|
            last_change = s.action_states.map { |a| a&.latest_execution&.last_status_change }.compact.max
            revisions = s.action_states.map { |a| a.current_revision&.revision_id&.slice(0,7) }.join(' ')
            ago = human_time_diff(now - last_change, 1)
            [s.stage_name, color(s.latest_execution.status, COLORS), "#{ago} ago", revisions].join(' ')
          end
          puts [set_color(now, :blue), stages].flatten.join('  ')
          sleep 5
        end
      end

    end
  end
end