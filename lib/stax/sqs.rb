require 'awful/sqs'

module Stax
  module Sqs
    def self.included(thor)
      thor.class_eval do

        no_commands do
          def sqs_queues
            @_sqs_queues ||= cf(:resources, [stack_name], type: 'AWS::SQS::Queue', quiet: true)
          end

          def sqs_queue_urls
            @_sqs_queue_urls ||= sqs_queues.map(&:physical_resource_id)
          end

          ## return url of queue with given logical id
          def sqs_queue_url(id)
            cf(:id, [stack_name, id], quiet: true)
          end
        end

        desc 'queues', 'list stack queues'
        def queues
          debug("SQS queues for stack #{stack_name}")
          sqs(:ls, sqs_queue_urls, long: true)
        end

        desc 'purge', 'purge SQS queues'
        def purge
          sqs_queues.each do |queue|
            name = queue.physical_resource_id.split('/').last
            next unless yes?("Really purge queue #{name}?", :yellow)

            debug("Purging queue #{name}")
            begin
              sqs(:purge, [queue.physical_resource_id])
            rescue Aws::SQS::Errors::PurgeQueueInProgress => e
              warn(e.message)
            end
          end
        end

      end
    end
  end
end