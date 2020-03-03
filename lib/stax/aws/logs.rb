require 'aws-sdk-cloudwatchlogs'

module Stax
  module Aws
    class Logs < Sdk

      class << self

        def client
          @_client ||= ::Aws::CloudWatchLogs::Client.new
        end

        def groups(prefix = nil)
          paginate(:log_groups) do |token|
            client.describe_log_groups(log_group_name_prefix: prefix, next_token: token)
          end
        end

        def streams(opt)
          client.describe_log_streams(opt).log_streams
        end

        def delete_group(name)
          client.delete_log_group(log_group_name: name)
        end

      end

    end
  end
end
