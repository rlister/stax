require 'stax/aws/rds'

module Stax
  module Rds
    def self.included(thor)
      thor.desc('rds COMMAND', 'RDS subcommands')
      thor.subcommand(:rds, Cmd::Rds)
    end
  end

  module Cmd
    class Rds < SubCommand
      stax_info :clusters, :instances, :endpoints

      COLORS = {
        available: :green,
        'in-sync': :green,
        Complete:  :green,
        Active:    :green,
      }

      no_commands do
        def stack_db_clusters
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::RDS::DBCluster')
        end

        def stack_db_instances
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::RDS::DBInstance')
        end

        def stack_rds_clusters
          filter = { name: 'db-cluster-id', values: stack_db_clusters.map(&:physical_resource_id) }
          Aws::Rds.clusters(filters: [filter])
        end

        def stack_rds_instances
          filter = { name: 'db-instance-id', values: stack_db_instances.map(&:physical_resource_id) }
          Aws::Rds.instances(filters: [filter])
        end

        def stack_db_subnet_groups
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::RDS::DBSubnetGroup')
        end

        def print_rds_events(opt)
          Aws::Rds.client.describe_events(opt).map(&:events).flatten.map do |e|
            [ e.date, e.message ]
          end.tap(&method(:print_table))
        end

      end

      desc 'ls', 'list clusters with members'
      def ls
        debug("RDS databases for #{my.stack_name}")
        stack_rds_clusters.map do |c|
          cluster = [ c.db_cluster_identifier, 'cluster', color(c.status), c.engine ]
          instances = c.db_cluster_members.map do |m|
            role = m.is_cluster_writer ? 'writer' : 'reader'
            i = Aws::Rds.instances(filters: [ { name: 'db-instance-id', values: [ m.db_instance_identifier ] } ]).first
            [ '- ' + i.db_instance_identifier, role, color(i.db_instance_status), i.engine, i.availability_zone, i.db_instance_class ]
          end
          [ cluster ] + instances
        end.flatten(1).tap do |list|
          print_table list
        end
      end

      desc 'clusters', 'list db clusters for stack'
      def clusters
        debug("RDS DB clusters for #{my.stack_name}")
        print_table stack_rds_clusters.map { |c|
          [c.db_cluster_identifier, c.engine, c.engine_version, color(c.status), c.cluster_create_time]
        }
      end

      desc 'members', 'list db cluster members for stack'
      def members
        stack_rds_clusters.each do |c|
          debug("RDS DB members for cluster #{c.db_cluster_identifier}")
          print_table c.db_cluster_members.map { |m|
            role = m.is_cluster_writer ? 'writer' : 'reader'
            [m.db_instance_identifier, role, m.db_cluster_parameter_group_status]
          }
        end
      end

      desc 'instances', 'list db instances for stack'
      def instances
        debug("RDS DB instances for #{my.stack_name}")
        print_table stack_rds_instances.map { |i|
          [i.db_instance_identifier, i.engine, i.engine_version, color(i.db_instance_status), i.db_instance_class, i.db_subnet_group&.vpc_id, i.availability_zone]
        }
      end

      desc 'endpoints', 'list db instance endpoints'
      def endpoints
        stack_rds_clusters.each do |c|
          debug("RDS DB endpoints for cluster #{c.db_cluster_identifier}")
          print_table [
            ['writer', c.endpoint,        c.port, c.hosted_zone_id],
            ['reader', c.reader_endpoint, c.port, c.hosted_zone_id],
          ]
        end

        debug("RDS DB instance endpoints for #{my.stack_name}")
        print_table stack_rds_instances.map { |i|
          [i.db_instance_identifier, i.endpoint&.address, i.endpoint&.port, i.endpoint&.hosted_zone_id]
        }
      end

      desc 'subnets', 'list db subnet groups'
      def subnets
        stack_db_subnet_groups.map do |r|
          Aws::Rds.subnet_groups(db_subnet_group_name: r.physical_resource_id)
        end.flatten.each do |g|
          debug("Subnets for group #{g.db_subnet_group_name}")
          print_table g.subnets.map { |s|
            [s&.subnet_availability_zone&.name, s&.subnet_identifier, color(s&.subnet_status)]
          }
        end
      end

      desc 'failover', 'failover clusters'
      method_option :target, type: :string, default: nil, desc: 'id of instance to promote'
      def failover
        stack_rds_clusters.each do |c|
          if yes?("Failover #{c.db_cluster_identifier}?", :yellow)
            resp = Aws::Rds.client.failover_db_cluster(db_cluster_identifier: c.db_cluster_identifier, target_db_instance_identifier: options[:target])
            puts "failing over #{resp.db_cluster.db_cluster_identifier}"
          end
        end
      end

      desc 'snapshots', 'list snapshots for stack clusters'
      def snapshots
        stack_db_clusters.map(&:physical_resource_id).each do |id|
          debug("Snapshots for cluster #{id}")
          Aws::Rds.client.describe_db_cluster_snapshots(db_cluster_identifier: id).map(&:db_cluster_snapshots).flatten.map do |s|
            [ s.db_cluster_snapshot_identifier, s.snapshot_create_time, "#{s.allocated_storage}G", color(s.status), s.snapshot_type ]
          end.tap do |list|
            print_table list
          end
        end
      end

      desc 'events', 'list rds events for this stack'
      option :duration, aliases: '-d', type: :numeric, default: 60*24, desc: 'duration in mins to show'
      def events
        stack_db_clusters.map(&:physical_resource_id).each do |id|
          debug("Events for cluster #{id}")
          print_rds_events(duration: options[:duration], source_type: 'db-cluster', source_identifier: id)
        end

        stack_db_instances.map(&:physical_resource_id).each do |id|
          debug("Events for instance #{id}")
          print_rds_events(duration: options[:duration], source_type: 'db-instance', source_identifier: id)
        end
      end

    end
  end
end
