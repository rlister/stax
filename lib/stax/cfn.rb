module Stax
  class Stack < Base
    include Aws

    desc 'parameters', 'show stack input parameters'
    def parameters
      print_table Cfn.parameters(stack_name).each_with_object({}) { |p, h|
        h[p.parameter_key] = p.parameter_value
      }.sort
    end

    desc 'template', 'get template of existing stack from cloudformation'
    method_option :pretty, type: :boolean, default: true, desc: 'format json output'
    def template
      Cfn.template(stack_name).tap { |t|
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

    desc 'resources', 'list resources for this stack'
    method_option :match, aliases: '-m', type: :string, default: nil, desc: 'filter by resource regex'
    def resources
      print_table Cfn.resources(stack_name).tap { |resources|
        if options[:match]
          m = Regexp.new(options[:match], Regexp::IGNORECASE)
          resources.select! { |r| m.match(r.resource_type) }
        end
      }.map { |r|
        [r.logical_resource_id, r.resource_type, color(r.resource_status, Cfn::COLORS), r.physical_resource_id]
      }
    end

    desc 'id [LOGICAL_ID]', 'get physical ID from resource logical ID'
    def id(resource)
      puts Cfn.id(stack_name, resource)
    end

    desc 'outputs', 'show stack outputs'
    def outputs(key = nil)
      if key
        puts Cfn.output(stack_name, key)
      else
        print_table Cfn.outputs(stack_name)
      end
    end

    desc 'delete', 'delete stack'
    def delete
      if yes? "Really delete stack #{stack_name}?", :yellow
        Cfn.delete(stack_name)
      end
    end

  end
end