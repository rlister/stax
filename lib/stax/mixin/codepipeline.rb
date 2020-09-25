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
      stax_info :state

      COLORS = {
        Succeeded: :green,
        Failed:    :red,
        Stopped:   :red,
        Abandoned: :red,
        enabled:   :green,
        disabled:  :red,
      }

      no_commands do
        def pipeline_link(name)
          "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/#{name}/view?region=#{aws_region}"
        end
      end

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
        my.stack_pipeline_names.each do |name|
          state = Aws::Codepipeline.state(name)
          debug("State for #{name} at #{state.updated}")
          print_table state.stage_states.map { |s|
            s.action_states.map { |a|
              l = a.latest_execution
              percent = (l&.percent_complete || 100).to_s + '%'
              sha = a.current_revision&.revision_id&.slice(0,7)
              ago = (t = l&.last_status_change) ? human_time_diff(Time.now - t, 1) : '?'
              [s.stage_name, a.action_name, color(l&.status || '', COLORS), percent, "#{ago} ago", (sha || l&.token), l&.error_details&.message]
            }
          }.flatten(1)
        end
      end

      desc 'approvals', 'approve or reject pending approvals'
      method_option :approved, type: :boolean, default: false, desc: 'approve the request'
      method_option :rejected, type: :boolean, default: false, desc: 'reject the request'
      def approvals
        my.stack_pipeline_names.each do |name|
          debug("Pending approvals for #{name}")
          Aws::Codepipeline.state(name).stage_states.each do |s|
            s.action_states.each do |a|
              next unless (a.latest_execution&.token && a.latest_execution&.status == 'InProgress')
              l = a.latest_execution
              ago = (t = l&.last_status_change) ? human_time_diff(Time.now - t, 1) : '?'
              puts "#{a.action_name} #{l&.token} #{ago} ago"
              resp = (options[:approved] && :approved) || (options[:rejected] && :rejected) || ask('approved,rejected,[skip]?', :yellow)
              status = resp.to_s.capitalize
              if (status == 'Rejected') || (status == 'Approved')
                Aws::Codepipeline.client.put_approval_result(
                  pipeline_name: name,
                  stage_name: s.stage_name,
                  action_name: a.action_name,
                  token: l.token,
                  result: {status: status, summary: "#{status} by #{ENV['USER']}"},
                ).tap { |r| puts "#{status} at #{r&.approved_at}" }
              end
            end
          end
        end
      end

      desc 'start [NAME]', 'start execution for pipeline'
      def start(name = nil)
        name ||= my.stack_pipeline_names.first
        debug("Starting execution for #{name}")
        puts Aws::Codepipeline.start(name)
        tail name
      end

      desc 'stop [NAME]', 'stop execution for pipeline'
      method_option :abandon, aliases: '-a', type: :boolean, default: false, desc: 'do not finish in-progress actions'
      method_option :reason,  aliases: '-r', type: :string,  default: nil,   desc: 'comment on reason for stop'
      def stop(name = nil)
        name ||= my.stack_pipeline_names.first
        id = Aws::Codepipeline.state(name).stage_states.first.latest_execution.pipeline_execution_id
        debug("Stopping #{name} #{id}")
        puts Aws::Codepipeline.client.stop_pipeline_execution(
          pipeline_name: name,
          pipeline_execution_id: id,
          abandon: options[:abandon],
          reason: options[:reason],
        ).pipeline_execution_id
      rescue ::Aws::CodePipeline::Errors::ServiceError => e
        fail_task(e.message)
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
            ago = last_change ? human_time_diff(now - last_change, 1) : '?'
            [s.stage_name, color(s&.latest_execution&.status || '', COLORS), "#{ago} ago", revisions].join(' ')
          end
          puts [set_color(now, :blue), stages].flatten.join('  ')
          sleep 5
        end
      end

      desc 'transitions', 'control pipeline stage transitions'
      method_option :enable,  aliases: '-e', type: :string, default: nil, desc: 'enable stage transition'
      method_option :disable, aliases: '-d', type: :string, default: nil, desc: 'disable stage transition'
      def transitions
        my.stack_pipeline_names.each do |name|
          if options[:enable]
            debug("Enable stage transition for #{name} #{options[:enable]}")
            Aws::Codepipeline.client.enable_stage_transition(
              pipeline_name: name,
              stage_name: options[:enable],
              transition_type: :Inbound,
            )
          elsif options[:disable]
            debug("Disable stage transition for #{name} #{options[:disable]}")
            Aws::Codepipeline.client.disable_stage_transition(
              pipeline_name: name,
              stage_name: options[:disable],
              transition_type: :Inbound,
              reason: ask('reason for disable?')
            )
          else
            debug("Stage transitions for #{name}")
            state = Aws::Codepipeline.state(name)
            print_table state.stage_states.map { |s|
              t = s.inbound_transition_state
              [ s.stage_name, color(t.enabled ? :enabled : :disabled, COLORS), t.disabled_reason, t.last_changed_at ]
            }
          end
        end
      end

      desc 'webhooks', 'list webhooks for pipelines'
      def webhooks
        webhooks = Aws::Codepipeline.client.list_webhooks.map(&:webhooks).flatten
        my.stack_pipeline_names.each do |pipeline|
          debug("Webhooks for pipeline #{pipeline}")
          print_table webhooks.select { |w|
            w.definition.target_pipeline == pipeline
          }.map { |w|
            [ w.definition.name, w.definition.target_pipeline, w.error_message, w.last_triggered ]
          }
        end
      end

      desc 'link', 'link to pipelines in aws console'
      def link
        my.stack_pipeline_names.each do |name|
          puts pipeline_link(name)
        end
      end

      desc 'open', 'open pipelines in aws console'
      def open
        my.stack_pipeline_names.each do |name|
          os_open(pipeline_link(name))
        end
      end

    end
  end
end
