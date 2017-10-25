require 'stax/aws/logs'

module Stax
  module Logs

    def self.included(thor)
      thor.desc(:logs, 'Logs subcommands')
      thor.subcommand(:logs, Cmd::Logs)
    end

    def stack_log_groups
      Aws::Cfn.resources_by_type(stack_name, 'AWS::Logs::LogGroup')
    end

    ## override this to customize
    def log_group_names
      stack_log_groups.map(&:physical_resource_id)
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
      end

      desc 'groups', 'list log groups for stack'
      def groups
        print_table my.log_group_names.map { |name|
          l = Aws::Logs.groups(name).first
          [l.log_group_name, l.retention_in_days, human_time(l.creation_time), human_bytes(l.stored_bytes)]
        }
      end

      desc 'streams', 'list log streams'
      method_option :alpha, aliases: '-a', type: :boolean, default: false, desc: 'order by name'
      method_option :limit, aliases: '-n', type: :numeric, default: nil,   desc: 'number of streams to list'
      def streams
        my.log_group_names.each do |group|
          debug("Log streams for group #{group}")
          streams = Aws::Logs.streams(
            log_group_name: group,
            order_by: options[:alpha] ? :LogStreamName : :LastEventTime,
            descending: !options[:alpha],
            limit: options[:limit],
          )
          print_table streams.map { |s|
            [s.log_stream_name, human_time(s.last_event_timestamp), human_bytes(s.stored_bytes)]
          }
        end
      end

      desc 'tail [STREAM]', 'tail latest/given log stream'
      method_option :numlines, aliases: '-n', type: :numeric, default: 10,    desc: 'number of lines to show'
      method_option :follow,   aliases: '-f', type: :boolean, default: false, desc: 'follow log output'
      method_option :sleep,    aliases: '-s', type: :numeric, default: 1,     desc: 'seconds to sleep between poll for new data'
      def tail(stream = nil)
        trap('SIGINT', 'EXIT')    # clean exit with ctrl-c
        group  = my.log_group_names.first
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

    end
  end
end