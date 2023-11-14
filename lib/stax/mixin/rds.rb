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
        COMPLETED: :green,
        AVAILABLE: :green,
        SWITCHOVER_COMPLETED: :green,
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

      desc 'create-upgrade-candidate', 'create blue/green deployment'
      method_option :target_engine_version, type: :string, default: '', desc: 'target engine version'
      method_option :target_cluster_parameter_group, type: :string, default: '', desc: 'target cluster parameter group'
      method_option :target_instance_parameter_group, type: :string, default: '', desc: 'target instance parameter group'
      method_option :target_db_instance_class, type: :string, default: '', desc: 'target instance class'
      def create_upgrade_candidate
        target_engine_version = options[:target_engine_version]
        target_cluster_parameter_group = options[:target_cluster_parameter_group]
        target_instance_parameter_group = options[:target_instance_parameter_group]
        target_db_instance_class = options[:target_db_instance_class]

        unless stack_rds_clusters.is_a?(Array) && stack_rds_clusters.any?
          say("No DB clusters associated with #{my.stack_name}", :red)
          return
        end        

        # get cluster source_arn from stack
        if stack_rds_clusters.length == 1
          source_arn = stack_rds_clusters[0].db_cluster_arn
        else
          say("Multiple DB Clusters associated with #{my.stack_name}. Cannot determine which cluster to use as source.", :red)
          return
        end

        # Specify the required blue/green deployment parameters
        deployment_params = {
          blue_green_deployment_name: "#{my.stack_name}-next-#{SecureRandom.alphanumeric(12)}",
          source: source_arn,
        }

        # Check if optional values are set and add them to the deployment parameters
        if !target_engine_version.empty?
          deployment_params[:target_engine_version] = target_engine_version
        end

        if !target_cluster_parameter_group.empty?
          deployment_params[:target_db_cluster_parameter_group_name] = target_cluster_parameter_group
        end

        if !target_instance_parameter_group.empty?
          deployment_params[:target_db_parameter_group_name] = target_instance_parameter_group
        end

        if !target_db_instance_class.empty?
          deployment_params[:target_db_instance_class] = target_db_instance_class
        end

        say("Creating blue/green deployment #{deployment_params[:blue_green_deployment_name]} for #{source_arn}", :yellow)
        resp = Aws::Rds.client.create_blue_green_deployment(deployment_params)
        if resp.blue_green_deployment.status != "PROVISIONING"
          say("Failed to create blue/green deployment #{deployment_params[:blue_green_deployment_name]}", :red)
          puts resp.to_h
          return
        end

        invoke(:tail_upgrade_candidate, [], id: resp.blue_green_deployment.blue_green_deployment_identifier)
      end

      desc 'delete-upgrade-candidate', 'delete blue/green deployment'
      method_option :id, type: :string, required: true, desc: 'id of blue/green deployment to delete'
      method_option :delete_target, type: :boolean, default: false, desc: 'delete resources in green deployment'
      def delete_upgrade_candidate
        deployment_identifier = options[:id]
        delete_target = options[:delete_target]

        # Future TODO: Even though the RDS API doesn't allow for target resources to be deleted 
        # post-switchover (likely because these resources are the old DB resources), we could
        # allow for an automatic clean up the leftover resources by deleting these resources
        # with specific RDS API calls.
        if delete_target && Aws::Rds.client.describe_blue_green_deployments({ blue_green_deployment_identifier: deployment_identifier }).blue_green_deployments[0].status == "SWITCHOVER_COMPLETED"
          say("You can't specify --delete-target if the blue/green deployment status is SWITCHOVER_COMPLETED", :red)
          return
        end

        if yes?("Really delete blue/green deployment #{deployment_identifier}?", :yellow)
          say("Deleting blue/green deployment #{deployment_identifier}", :red)
          resp = Aws::Rds.client.delete_blue_green_deployment({
            blue_green_deployment_identifier: deployment_identifier,
            delete_target: delete_target,
          })

          if resp.blue_green_deployment.status != "DELETING"
            say("Failed to delete blue/green deployment #{deployment_identifier}", :red)
            puts resp.to_h
            return
          end

          # tail the blue/green deployment until it is deleted
          begin
            invoke(:tail_upgrade_candidate, [], id: deployment_identifier)
          # TODO: figure out how to catch this specific exception
          # rescue Aws::RDS::Errors::BlueGreenDeploymentNotFoundFault
          rescue  
            say("Deleted blue/green deployment #{deployment_identifier}", :green)
          end
        end
      end

      desc 'switchover-upgrade-candidate', 'switchover blue/green deployment'
      method_option :id, type: :string, required: true, desc: 'id of blue/green deployment'
      method_option :timeout, type: :numeric, default: 300, desc: 'amount of time, in seconds, for the switchover to complete'
      def switchover_upgrade_candidate
        deployment_identifier = options[:id]
        timeout = options[:timeout]

        if yes?("Really switchover blue/green deployment #{deployment_identifier}?", :yellow)
          say("Switchover blue/green deployment #{deployment_identifier}", :yellow)
          resp = Aws::Rds.client.switchover_blue_green_deployment({
            blue_green_deployment_identifier: deployment_identifier,
            switchover_timeout: timeout,
          })

          if resp.blue_green_deployment.status != "SWITCHOVER_IN_PROGRESS"
            say("Failed to switchover blue/green deployment #{deployment_identifier}", :red)
            puts resp.to_h
            return
          end

          # tail the blue/green deployment until it is complete
          invoke(:tail_upgrade_candidate, [], id: deployment_identifier)
        end
      end

      desc 'tail-upgrade-candidate', 'tail blue/green deployment'
      method_option :id, type: :string, required: true, desc: 'id of blue/green deployment'
      def tail_upgrade_candidate
        deployment_identifier = options[:id]

        previous_status = nil
        previous_switchover_details = []
        previous_tasks = []
      
        loop do
          resp = Aws::Rds.client.describe_blue_green_deployments({
            blue_green_deployment_identifier: deployment_identifier, 
          })
      
          if resp[:blue_green_deployments].empty?
            say("Deployment not found: #{deployment_identifier}", :red)
            return
          end
      
          deployment = resp[:blue_green_deployments][0]

          current_status = color(deployment[:status])
          current_switchover_details = deployment[:switchover_details]
          current_tasks = deployment[:tasks]

          if previous_status.nil?
            say("Deployment Name: #{deployment[:blue_green_deployment_name]}", :blue)
            say("Deployment ID: #{deployment_identifier}", :white)
            say("Create Time: #{deployment[:create_time]}", :green)
          end
            
          if previous_status.nil? || previous_status != current_status
            print_table [[Time.now.utc.strftime('%Y-%m-%d %H:%M:%S UTC'), "Deployment Status", current_status]]
          end

          if !current_switchover_details.nil?
            current_switchover_details.each do |current_item|
              previous_item = previous_switchover_details.find { |item| item[:source_member] == current_item[:source_member] }
              
              if previous_item.nil? || current_item != previous_item
                if current_item[:target_member].nil?
                  prefix = "#{set_color('Pending DB Resource', :cyan)}"
                else
                  prefix = current_item[:target_member].include?(':cluster:') ? "#{set_color('DB Cluster', :cyan)}" : "#{set_color('DB Instance', :cyan)}"
                end
                print_table [[Time.now.utc.strftime('%Y-%m-%d %H:%M:%S UTC'), prefix, current_item[:target_member], color(current_item[:status] || :CREATING)]]
              end
            end
          end
      
          if !current_tasks.nil?
            current_tasks.each do |current_item|
              previous_item = previous_tasks.find { |item| item[:name] == current_item[:name] }
        
              if previous_item.nil? || current_item != previous_item
                print_table [[Time.now.utc.strftime('%Y-%m-%d %H:%M:%S UTC'), "#{set_color('Task', :magenta)}", current_item[:name], color(current_item[:status])]]
              end
            end
          end

          if deployment[:status] == "AVAILABLE"
            say("Deployment is complete.", :green)
            break
          end

          if deployment[:status] == "SWITCHOVER_COMPLETED"
            say("Deployment switchover is complete.", :green)
            break
          end

          previous_status = current_status
          previous_switchover_details = current_switchover_details
          previous_tasks = current_tasks
      
          sleep 10  # Wait for 10 seconds before polling again
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

      desc 'write-forwarding', 'control write-forwarding'
      method_option :disable, aliases: '-d', type: :boolean, desc: 'disable write-forwarding'
      method_option :enable,  aliases: '-e', type: :boolean, desc: 'enable write-forwarding'
      def write_forwarding
        stack_db_clusters.map(&:physical_resource_id).each do |cluster|
          if options[:enable]
            puts "#{cluster} enabling write-forwarding"
            Aws::Rds.client.modify_db_cluster(db_cluster_identifier: cluster, enable_global_write_forwarding: true)
          elsif options[:disable]
            puts "#{cluster} disabling write-forwarding"
            Aws::Rds.client.modify_db_cluster(db_cluster_identifier: cluster, enable_global_write_forwarding: false)
          else
            print_table Aws::Rds.client.describe_db_clusters(db_cluster_identifier: cluster).db_clusters.map { |c|
              [ c.db_cluster_identifier, c.global_write_forwarding_status || '-' ]
            }
          end
        end
      end

    end
  end
end
