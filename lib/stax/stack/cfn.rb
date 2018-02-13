module Stax
  class Stack < Base

    desc 'template', 'get template of existing stack from cloudformation'
    method_option :pretty, type: :boolean, default: true, desc: 'format json output'
    def template
      Aws::Cfn.template(stack_name).tap { |t|
        puts options[:pretty] ? JSON.pretty_generate(JSON.parse(t)) : t
      }
    end

    desc 'events', 'show all events for stack'
    method_option :number, aliases: '-n', type: :numeric, default: nil, desc: 'show n most recent events'
    def events
      print_table Cfn.events(stack_name).tap { |events|
        events.replace(events.first(options[:number])) if options[:number]
      }.reverse.map { |e|
        [e.timestamp, color(e.resource_status, Cfn::COLORS), e.resource_type, e.logical_resource_id, e.resource_status_reason]
      }
    end

  end
end