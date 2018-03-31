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

    end
  end
end