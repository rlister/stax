require 'stax/aws/sqs'

module Stax
  module Sqs
    def self.included(thor)
      thor.desc(:sqs, 'SQS subcommands')
      thor.subcommand(:sqs, Cmd::Sqs)
    end
  end

  module Cmd
    class Sqs < SubCommand

      no_commands do
        def stack_sqs_queues
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::SQS::Queue')
        end
      end

      desc 'ls', 'SQS queues'
      def ls
        print_table stack_sqs_queues.map { |r|
          q = Aws::Sqs.get(r.physical_resource_id)
          [
            q['QueueArn'].split(':').last,
            q['ApproximateNumberOfMessages'],
            q['ApproximateNumberOfMessagesNotVisible'],
            Time.at(q['LastModifiedTimestamp'].to_i),
          ]
        }
      end

      desc 'purge', 'purge SQS queues'
      def purge
        stack_sqs_queues.each do |q|
          name = q.physical_resource_id.split('/').last
          if yes?("Purge queue #{name}?", :yellow)
            begin
              Aws::Sqs.purge(q.physical_resource_id)
            rescue ::Aws::SQS::Errors::PurgeQueueInProgress => e
              warn(e.message)
            end
          end
        end
      end

    end
  end
end