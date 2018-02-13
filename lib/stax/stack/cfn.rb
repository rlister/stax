module Stax
  class Stack < Base

    no_commands do

      def event_fields(e)
        [e.timestamp, color(e.resource_status, Aws::Cfn::COLORS), e.resource_type, e.logical_resource_id, e.resource_status_reason]
      end

      def print_events(events)
        events.reverse.each do |e|
          puts "%s  %-44s  %-40s  %-20s  %s" % event_fields(e)
        end
      end

    end

    desc 'template', 'get template of existing stack from cloudformation'
    method_option :pretty, type: :boolean, default: true, desc: 'format json output'
    def template
      Aws::Cfn.template(stack_name).tap { |t|
        puts options[:pretty] ? JSON.pretty_generate(JSON.parse(t)) : t
      }
    end

    desc 'events', 'show all events for stack'
    method_option :number, aliases: '-n', type: :numeric, default: 0, desc: 'show n most recent events'
    def events
      print_events(Aws::Cfn.events(stack_name)[0..options[:number]-1])
    rescue ::Aws::CloudFormation::Errors::ValidationError => e
      puts e.message
    end

    desc 'tail', 'tail stack events'
    method_option :number, aliases: '-n', type: :numeric, default: nil, desc: 'number of historic events to show'
    def tail
      trap('SIGINT', 'EXIT')    # clean exit with ctrl-c

      ## print some historical events
      events = Aws::Cfn.events(stack_name).first(options[:number] || 1)
      return unless events
      print_events(events)
      last_seen = events&.first&.event_id

      loop do
        sleep(1)
        events = []

        Aws::Cfn.events(stack_name).each do |e|
          (last_seen == e.event_id) ? break : events << e
        end

        unless events.empty?
          print_events(events)
          last_seen = events.first.event_id
        end

        break if Aws::Cfn.describe(stack_name).stack_status.end_with?('COMPLETE', 'FAILED')
      end
    rescue ::Aws::CloudFormation::Errors::ValidationError => e
      puts e.message
    end

  end
end