require 'json'

module Stax
  module Aws
    class DynamoDB < Sdk

      class << self

        def client
          @_client ||= ::Aws::DynamoDB::Client.new
        end

        def table(name)
          client.describe_table(table_name: name).table
        end

        def gsi(name)
          client.describe_table(table_name: name).table.global_secondary_indexes || []
        end

        def lsi(name)
          client.describe_table(table_name: name).table.local_secondary_indexes || []
        end

        def key_schema(name)
          client.describe_table(table_name: name).table.key_schema
        end

        ## key schema as a hash
        def keys(name)
          key_schema(name).each_with_object({}) do |s, h|
            h[s.key_type.downcase.to_sym] = s.attribute_name
          end
        end

        def do_scan(opt)
          exclusive_start_key = nil
          loop do
            r = client.scan(opt.merge(exclusive_start_key: exclusive_start_key))
            yield r
            exclusive_start_key = r.last_evaluated_key
            break unless exclusive_start_key
          end
        end

        def scan(opt)
          do_scan(opt) do |r|
            r.items.each do |item|
              puts JSON.generate(item)
            end
          end
        end

        def count(opt)
          total = 0
          do_scan(opt.merge(select: 'COUNT')) do |r|
            total += r.count
          end
          return total
        end

        def query(opt)
          exclusive_start_key = nil
          loop do
            r = client.query(opt.merge(exclusive_start_key: exclusive_start_key))
            r.items.each do |item|
              puts JSON.generate(item)
            end
            exclusive_start_key = r.last_evaluated_key
            break unless exclusive_start_key
          end
        end

        def list_backups(opt = {})
          last_arn = nil
          backups = []
          loop do
            r = client.list_backups(opt.merge(exclusive_start_backup_arn: last_arn))
            backups += r.backup_summaries
            last_arn = r.last_evaluated_backup_arn
            break unless last_arn
          end
          backups
        end

      end

    end
  end
end