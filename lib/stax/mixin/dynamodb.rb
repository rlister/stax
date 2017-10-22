require 'stax/aws/dynamodb'

module Stax
  module DynamoDB
    def self.included(thor)
      thor.desc(:dynamodb, 'Dynamo subcommands')
      thor.subcommand(:dynamodb, Cmd::DynamoDB)
    end
  end

  module Cmd
    class DynamoDB < SubCommand

      COLORS = {
        CREATING: :yellow,
        UPDATING: :yellow,
        DELETING: :red,
        ACTIVE:   :green,
      }

      no_commands do
        def stack_tables
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::DynamoDB::Table')
        end
      end

      desc 'tables', 'list tables for stack'
      def tables
        print_table stack_tables.map { |r|
          t = Aws::DynamoDB.table(r.physical_resource_id)
          [ t.table_name, color(t.table_status, COLORS), t.item_count, t.table_size_bytes, t.creation_date_time ]
        }
      end

    end
  end
end