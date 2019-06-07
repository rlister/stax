require 'stax/aws/logs'

module Stax
  module Logs

    def self.included(thor)
      thor.desc('logs COMMAND', 'Logs subcommands')
      thor.subcommand(:logs, Cmd::Logs)
    end

    def stack_log_groups
      @_stack_log_groups ||= stack_resources_by_type('AWS::Logs::LogGroup')
    end

  end

  module Cmd
    class Logs < SubCommand

      no_commands do
        ## n-th most-recently updated stream
        def latest_stream(group, n = 0)
          n = n.to_i.abs          # convert string and -ves
          Aws::Logs.streams(log_group_name: group, order_by: :LastEventTime, descending: true, limit: n+1)[n]
        end

        ## hash of resource id to log group objects, including lambda auto-created groups
        def log_groups
          {}.tap do |h|
            my.stack_resources_by_type('AWS::Logs::LogGroup').each do |r|
              h[r.logical_resource_id] = Aws::Logs.groups(r.physical_resource_id)&.first
            end
            my.stack_resources_by_type('AWS::Lambda::Function').each do |r|
              h[r.logical_resource_id] = Aws::Logs.groups("/aws/lambda/#{r.physical_resource_id}")&.first
            end
            my.stack_resources_by_type('AWS::CodeBuild::Project').each do |r|
              h[r.logical_resource_id] = Aws::Logs.groups("/aws/codebuild/#{r.physical_resource_id}")&.first
            end
          end.compact # lambda and codebuild groups may be nil if not invoked yet
        end
      end

      desc 'groups', 'list log groups for stack'
      def groups
        print_table log_groups.map { |id, g|
          [id, g.log_group_name, g.retention_in_days, human_time(g.creation_time), human_bytes(g.stored_bytes)]
        }
      end

      desc 'streams', 'list log streams'
      method_option :alpha, aliases: '-a', type: :boolean, default: false, desc: 'order by name'
      method_option :limit, aliases: '-n', type: :numeric, default: nil,   desc: 'number of streams to list'
      def streams
        log_groups.each do |id, group|
          debug(group.log_group_name)
          streams = Aws::Logs.streams(
            log_group_name: group.log_group_name,
            order_by: options[:alpha] ? :LogStreamName : :LastEventTime,
            descending: !options[:alpha], # most recent first
            limit: options[:limit],
          )
          print_table streams.map { |s|
            [s.log_stream_name, human_time(s.last_event_timestamp), human_bytes(s.stored_bytes)]
          }
        end
      end

      desc 'events [STREAM]', 'show events just from latest/given log stream'
      method_option :group,    aliases: '-g', type: :string,  default: nil,   desc: 'log group to tail'
      method_option :numlines, aliases: '-n', type: :numeric, default: 10,    desc: 'number of lines to show'
      method_option :follow,   aliases: '-f', type: :boolean, default: false, desc: 'follow log output'
      method_option :sleep,    aliases: '-s', type: :numeric, default: 1,     desc: 'seconds to sleep between poll for new data'
      def events(stream = nil)
        trap('SIGINT', 'EXIT')    # clean exit with ctrl-c
        group  = ((g = options[:group]) ? log_groups[g] : log_groups.values.first).log_group_name
        stream ||= latest_stream(group).log_stream_name

        debug("Log stream #{group}/#{stream}")
        token = nil
        loop do
          resp = Aws::Logs.client.get_log_events(
            log_group_name: group,
            log_stream_name: stream,
            limit: options[:numlines],
            next_token: token,
          )
          resp.events.each do |e|
            puts("#{set_color(human_time(e.timestamp).utc, :green)}  #{e.message}")
          end
          token = resp.next_forward_token
          options[:follow] ? sleep(options[:sleep]) : break
        end
      end

      desc 'tail', 'tail all events from log group'
      method_option :group,   aliases: '-g', type: :string, default: nil, desc: 'log group to tail'
      method_option :streams, aliases: '-s', type: :array,  default: nil, desc: 'limit to given streams'
      def tail
        trap('SIGINT', 'EXIT')    # clean exit with ctrl-c
        group  = ((g = options[:group]) ? log_groups[g] : log_groups.values.first).log_group_name

        debug("Log group #{group}")
        token = nil
        start_time = Time.now.to_i - 30 # start 30 sec ago

        loop do
          end_time = Time.now.to_i
          resp = Aws::Logs.client.filter_log_events(
            log_group_name: group,
            log_stream_names: options[:streams],
            start_time: start_time * 1000, # aws needs msec
            end_time: end_time * 1000,
            next_token: token,
            interleaved: true,
          )

          ## pretty-print the events
          resp.events.each do |e|
            puts("#{set_color(human_time(e.timestamp).utc, :green)}  #{set_color(e.log_stream_name, :blue)}  #{e.message}")
          end

          ## token means more data available from this request, so loop and get it right away
          token = resp.next_token

          ## no token, so sleep and start next request from end time of this one
          unless token
            start_time = end_time
            sleep 10
          end
        end
      end

      desc 'filter', 'filter events from log group'
      method_option :group,   aliases: '-g', type: :string, default: nil, desc: 'log group to filter'
      method_option :streams, aliases: '-s', type: :array,  default: nil, desc: 'limit to given streams'
      method_option :pattern, aliases: '-p', type: :string, default: nil, desc: 'pattern to filter logs'
      method_option :start,   aliases: '-t', type: :string, default: nil, desc: 'start time'
      method_option :end,     aliases: '-e', type: :string, default: nil, desc: 'end time'
      def filter
        trap('SIGINT', 'EXIT')    # clean exit with ctrl-c
        group = ((g = options[:group]) ? log_groups[g] : log_groups.values.first).log_group_name
        debug("Log group #{group}")

        start_time = options[:start] ? Time.parse(options[:start]).to_i*1000 : nil
        end_time   = options[:end]   ? Time.parse(options[:end]).to_i*1000   : nil
        token = nil
        loop do
          resp = Aws::Logs.client.filter_log_events(
            log_group_name: group,
            log_stream_names: options[:streams],
            next_token: token,
            start_time: start_time,
            end_time: end_time,
            filter_pattern: options[:pattern],
          )
          resp.events.each do |e|
            time   = set_color(human_time(e.timestamp).utc, :green)
            stream = set_color(e.log_stream_name, :blue)
            puts("#{time}  #{stream}  #{e.message}")
          end
          token = resp.next_token
          break unless token
        end
      end

      ## lambdas create their own log groups, and when we delete stack they are left behind;
      ## this task looks up their names by stack prefix, and deletes them
      desc 'cleanup', 'cleanup lambda log groups named for stack'
      method_option :test, aliases: '-t', type: :boolean, default: false, desc: 'show group names without deleting'
      def cleanup
        debug("Cleaning up log groups for stack #{my.stack_name}")
        Aws::Logs.groups("/aws/lambda/#{my.stack_name}").map(&:log_group_name).each do |name|
          puts name
          Aws::Logs.delete_group(name) unless options[:test]
        end
      end

    end
  end
end