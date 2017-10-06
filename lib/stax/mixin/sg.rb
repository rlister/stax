require 'stax/aws/sg'
require 'open-uri'

module Stax
  module Sg
    def self.included(thor)
      thor.desc(:sg, 'Security group subcommands')
      thor.subcommand(:sg, Cmd::Sg)
    end

    ## look up my local public IP
    def get_my_ip
      open('http://v4.ident.me/').read + '/32'
    end

    def sg_authorize(id, cidr = get_my_ip, port = 22)
      Aws::Sg.authorize(id, cidr, port)
    end

    def sg_revoke(id, cidr = get_my_ip, port = 22)
      Aws::Sg.revoke(id, cidr, port)
    end
  end

  module Cmd
    class Sg < SubCommand
      no_commands do
        def stack_security_groups
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::EC2::SecurityGroup')
        end

        def get_id(id)
          id.match(/^sg-\h{8}$/) ? id : Aws::Cfn.id(my.stack_name, id)
        end

        def stack_security_group(id)
          Aws::Sg.describe(get_id(id))
        end

        ## format permissions output
        def sg_permissions(perms)
          perms.map do |p|
            proto = (p.ip_protocol == '-1') ? 'all' : p.ip_protocol
            port = ((p.from_port == p.to_port) ? p.from_port : [p.from_port, p.to_port].join('-')) || 'all'
            [proto, port, p.ip_ranges.map(&:cidr_ip).join(','), p.user_id_group_pairs.map(&:group_id).join(',')]
          end
        end

        ## lookup my IP as a CIDR
        def get_my_ip
          open('http://v4.ident.me/').read + '/32'
        end

      end

      desc 'ls', 'SGs for stack'
      def ls
        print_table Aws::Sg.describe(stack_security_groups.map(&:physical_resource_id)).map { |s|
          [s.group_name, s.group_id, s.vpc_id, s.description]
        }
      end

      desc 'inbound ID', 'SG inbound permissions'
      def inbound
        stack_security_groups.each do |s|
          debug("Inbound permissions for #{s.logical_resource_id} #{s.physical_resource_id}")
          print_table sg_permissions(stack_security_group(s.physical_resource_id).first.ip_permissions)
        end
      end

      desc 'outbound ID', 'SG outbound permissions'
      def outbound
        stack_security_groups.each do |s|
          debug("Outbound permissions for #{s.logical_resource_id} #{s.physical_resource_id}")
          print_table sg_permissions(stack_security_group(s.physical_resource_id).first.ip_permissions_egress)
        end
      end

      desc 'authorize ID', 'open port on security group'
      method_option :cidr, type: :string,  default: nil, desc: 'cidr block to open'
      method_option :port, type: :numeric, default: 22,  desc: 'port to open'
      def authorize(id)
        Aws::Sg.authorize(get_id(id), options.fetch(:cidr, get_my_ip), options[:port])
      end

      desc 'revoke ID', 'close port on security group'
      method_option :cidr, type: :string,  default: nil, desc: 'cidr block to close'
      method_option :port, type: :numeric, default: 22,  desc: 'port to close'
      def revoke(id)
        Aws::Sg.revoke(get_id(id), options.fetch(:cidr, get_my_ip), options[:port])
      end

    end
  end
end