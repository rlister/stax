## include this mixin in stack classes that need ssh to instances
## and consider defining methods: ssh_options, before_ssh, after_ssh
require 'stax/aws/ec2'

module Stax
  module Ssh
    def self.included(thor)

      ## stack class can define this
      # def ssh_options
      #   {
      #     StrictHostKeyChecking: 'no',
      #     UserKnownHostsFile: '/dev/null',
      #   }
      # end

      ## IP address to ssh
      def ssh_instances
        Aws::Ec2.instances(stack_name).map(&:public_ip_address)
      end

      def ssh_options_format(opt)
        opt.reject do |_,v|
          v.nil?
        end.map do |k,v|
          "-o #{k}=#{v}"
        end.join(' ')
      end

      def ssh_cmd(instances, cmd = [], opt = {})
        c = cmd.join(' ')
        o = ssh_options_format((try(:ssh_options) || {}).merge(opt))
        instances.each do |i|
          system "ssh #{o} #{i} #{c}"
        end
      end

      thor.class_eval do

        ## stack class can add before/after_ssh hooks
        desc 'ssh [CMD]', 'ssh to ec2 instances'
        def ssh(*cmd)
          try(:before_ssh)
          ssh_cmd(ssh_instances, cmd)
          try(:after_ssh)
        end

      end
    end
  end
end