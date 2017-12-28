module Stax
  module Cmd
    class DynamoDB < SubCommand

      no_commands do
        def list_backups(name)
          debug("Backups for #{name}")
          print_table Aws::DynamoDB.list_backups(table_name: name).map { |b|
            [b.backup_name, color(b.backup_status, COLORS), b.table_name, b.backup_creation_date_time, human_bytes(b.backup_size_bytes)]
          }
        end

        def create_backup(table_name, backup_name)
          backup_name = Time.now.utc.strftime("#{table_name}-%Y%m%d%H%M%S") if backup_name == 'create' # thor option empty
          debug("Creating backup #{backup_name} from #{table_name}")
          Aws::DynamoDB.create_backup(table_name, backup_name).tap do |b|
            puts YAML.dump(stringify_keys(b.to_hash))
          end
        end
      end

      desc 'backup ID', 'table backups'
      method_option :create, aliases: '-c', type: :string, default: nil, desc: 'create new backup from table'
      def backup(id = nil)
        name = my.resource(id)
        if options[:create]
          create_backup(name, options[:create])
        else
          list_backups(name)
        end
      end

      desc 'restore ARN TABLE', 'restore backup to a new table'
      def restore(arn, table)
        debug("Creating table #{table} from backup #{arn}")
        Aws::DynamoDB.restore_backup(table, arn)
      end

    end
  end
end