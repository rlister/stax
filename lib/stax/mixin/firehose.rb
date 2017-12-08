require 'stax/aws/firehose'

module Stax
  module Firehose
    def self.included(thor)
      thor.desc(:firehose, 'Firehose subcommands')
      thor.subcommand(:firehose, Cmd::Firehose)

      def stack_firehoses
        Aws::Cfn.resources_by_type(stack_name,  'AWS::KinesisFirehose::DeliveryStream')
      end
    end
  end

  module Cmd
    class Firehose < SubCommand

      COLORS = {
        ACTIVE:   :green,
        CREATING: :yellow,
        DELETING: :red,
      }

      desc 'ls', 'list stack firehoses'
      def ls
        print_table my.stack_firehoses.map { |r|
          f = Aws::Firehose.describe(r.physical_resource_id)
          [f.delivery_stream_name, color(f.delivery_stream_status, COLORS), f.create_timestamp, f.delivery_stream_type]
        }
      end

    end
  end
end