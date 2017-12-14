module Stax
  module Cmd
    class DynamoDB < SubCommand

      no_commands do
        def print_throughput(ids)
          output = [['NAME', 'INDEX NAME', 'READ CAPACITY', 'WRITE CAPACITY', 'DECREASES TODAY']]
          stack_table_names(ids).each do |name|
            table = Aws::DynamoDB.table(name)
            t = table.provisioned_throughput
            output << [table.table_name, nil, t.read_capacity_units, t.write_capacity_units, t.number_of_decreases_today]
            (table.global_secondary_indexes || []).each do |gsi|
              t = gsi.provisioned_throughput
              output << [table.table_name, gsi.index_name, t.read_capacity_units, t.write_capacity_units, t.number_of_decreases_today]
            end
          end
          print_table(output)
        end

        def update_throughput(ids, read, write)
          debug("Updating throughput on #{ids ? ids.count : 'all'} tables")
          stack_table_names(ids).each do |name|
            puts name
            table = Aws::DynamoDB.table(name)
            begin
              Aws::DynamoDB.client.update_table(
                table_name: name,
                provisioned_throughput: {
                  read_capacity_units:  read  || table.provisioned_throughput.read_capacity_units,
                  write_capacity_units: write || table.provisioned_throughput.write_capacity_units,
                },
                global_secondary_index_updates: table.global_secondary_indexes&.map do |gsi|
                  {
                    update: {
                      index_name: gsi.index_name,
                      provisioned_throughput: {
                        read_capacity_units:  read  || gsi.provisioned_throughput.read_capacity_units,
                        write_capacity_units: write || gsi.provisioned_throughput.write_capacity_units,
                      }
                    }
                  }
                end
              )
            rescue ::Aws::DynamoDB::Errors::ValidationException
              puts 'no change'
            rescue ::Aws::DynamoDB::Errors::ResourceInUseException => e
              warn(e.message)
            end
          end
        end
      end

      desc 'throughput ID', 'throughput'
      method_option :tables, aliases: '-t', type: :array,   default: nil, desc: 'limit to given table IDs'
      method_option :read,   aliases: '-r', type: :numeric, default: nil, desc: 'set read capacity units'
      method_option :write,  aliases: '-w', type: :numeric, default: nil, desc: 'set write capacity units'
      def throughput
        if options[:write] || options[:read]
          update_throughput(options[:tables], options[:read], options[:write])
        else
          print_throughput(options[:tables])
        end
      end

    end
  end
end