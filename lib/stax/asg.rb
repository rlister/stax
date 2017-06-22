require 'awful/auto_scaling'

module Stax
  module Asg
    def self.included(thor)     # magic to make mixins work in Thor
      thor.class_eval do        # ... so magical

        class_option :groups, aliases: '-g', type: :array, default: nil, desc: 'limit ASGs returned by id'

        no_commands do
          def auto_scaling_groups
            cf(:resources, [stack_name], type: ['AWS::AutoScaling::AutoScalingGroup'], quiet: true).tap do |asgs|
              if options[:groups]
                ids = options[:groups].map { |group| prepend(:asg, group) }
                asgs.select! { |g| ids.include?(g.logical_resource_id) }
              end
            end
          end

          def auto_scaling_instances
            asg(:instances, auto_scaling_groups.map(&:physical_resource_id), describe: true, quiet: true)
          end

          ## get instance details from ec2
          def auto_scaling_describe_instances
            asgs = auto_scaling_groups.map(&:physical_resource_id)
            fail_task("No matching autoscaling groups") if asgs.empty?
            asg(:ips, auto_scaling_groups.map(&:physical_resource_id), quiet: true)
          end

          def asg_status
            auto_scaling_groups.each do |asg|
              debug("ASG status for #{asg.physical_resource_id}")
              asg(:instances, [asg.physical_resource_id], long: true)
            end
          end

          def asg_enter_standby(asg, *instances)
            debug("Taking #{instances.join(',')} out of ELB for #{asg}")
            instances.each do |instance| # one at a time so we can rescue each one
              begin
                asg(:enter_standby, [asg, instance])
              rescue Aws::AutoScaling::Errors::ValidationError => e
                warn(e.message)
              end
            end
          end

          def asg_exit_standby(asg, *instances)
            debug("Putting #{instances.join(',')} back into ELB")
            instances.each do |instance| # one at a time so we can rescue each one
              begin
                asg(:exit_standby, [asg, instance])
              rescue Aws::AutoScaling::Errors::ValidationError => e
                warn(e.message)
              end
            end
          end

          ## ssh to num instances from our asgs
          def auto_scaling_ssh(num, cmd, opts = {})
            opts = opts.reject{ |_,v| v.nil? }.map{ |k,v| "-o #{k}=#{v}" }.join(' ')
            auto_scaling_describe_instances.tap do |instances|
              instances = instances.last(num) if num
              instances.each do |i|
                debug("SSH to #{i.instance_id} #{i.public_ip_address}")
                system "ssh #{opts} #{i.public_ip_address} #{cmd}"
              end
            end
          end

          def ssh_options
            {
              User: 'core',
              StrictHostKeyChecking: 'no',
              UserKnownHostsFile: '/dev/null'
            }
          end
        end

        desc 'scale', 'scale number of instances in ASGs for stack'
        method_option :desired_capacity, aliases: '-d', type: :numeric, default: nil, desc: 'desired instance count for each ASG'
        method_option :min_size,         aliases: '-m', type: :numeric, default: nil, desc: 'set minimum capacity'
        method_option :max_size,         aliases: '-M', type: :numeric, default: nil, desc: 'set maximum capacity'
        def scale
          opt = options.slice(:desired_capacity, :min_size, :max_size)
          fail_task('No change requested') if opt.empty?

          auto_scaling_groups.tap do |asgs|
            warn('No matching auto-scaling groups') if asgs.empty?
          end.each do |asg|
            id = asg.physical_resource_id
            debug("Scaling to #{opt} for #{id}")
            asg(:update, [id], opt)
          end
        end

        desc 'old', 'list or terminate old instances from ASGs'
        method_option :terminate, aliases: '-t', type: :boolean, default: false, desc: 'terminate old instances'
        def old
          verb = options[:terminate] ? 'Terminating' : 'Listing'
          debug("#{verb} out-of-date instances in autoscaling groups")
          asgs = auto_scaling_groups.map(&:physical_resource_id)
          asg(:old_instances, asgs, terminate: options[:terminate])
        end

        desc 'standby', 'enter (or exit) standby for ASGs'
        method_option :exit,   aliases: '-x', type: :boolean, default: false, desc: 'exit standby instead of enter'
        def standby
          auto_scaling_instances.each_with_object(Hash.new {|h,k| h[k]=[]}) do |i, h|
            h[i.auto_scaling_group_name] << i.instance_id
          end.each do |asg, ins|
            options[:exit] ? asg_exit_standby(asg, *ins) : asg_enter_standby(asg, *ins)
          end
        end

        desc 'ssh [CMD]', 'ssh to ASG instances'
        method_option :number,  aliases: '-n', type: :numeric, default: nil,   desc: 'number of instances to ssh'
        method_option :verbose, aliases: '-v', type: :boolean, default: false, desc: 'verbose ssh client logging'
        def ssh(*cmd)
          keyfile = try(:key_pair_get) # get private key from param store
          try(:let_me_in_allow)        # open security group
          opts = ssh_options.merge(IdentityFile: keyfile.try(:path), LogLevel: (options[:verbose] ? 'DEBUG' : nil))
          auto_scaling_ssh(options[:number], cmd.join(' '), opts)
        ensure
          keyfile.try(:unlink)         # remove private key
          try(:let_me_in_revoke)       # close security group
        end

      end
    end
  end
end