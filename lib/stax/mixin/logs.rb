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

    def log_group_names
      stack_log_groups.map(&:physical_resource_id)
    end

  end

  module Cmd
    class Logs < SubCommand

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

    end
  end
end