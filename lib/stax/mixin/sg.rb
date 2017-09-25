require 'stax/aws/sg'

module Stax
  module SgTasks
    include Aws

    def self.included(thor)
      thor.class_eval do

        no_commands do
          def stack_security_groups
            Cfn.resources_by_type(stack_name, 'AWS::EC2::SecurityGroup')
          end

          def stack_security_group(id)
            sg = id.match(/^sg-\h{8}$/) ? id : Cfn.id(stack_name, id)
            Sg.describe(sg)
          end

          ## format permissions output
          def _sg_permissions(perms)
            perms.map do |p|
              proto = (p.ip_protocol == '-1') ? 'all' : p.ip_protocol
              port = ((p.from_port == p.to_port) ? p.from_port : [p.from_port, p.to_port].join('-')) || 'all'
              [proto, port, p.ip_ranges.map(&:cidr_ip).join(','), p.user_id_group_pairs.map(&:group_id).join(',')]
            end
          end
        end

        desc 'sg-list', 'SGs for stack'
        def sg_list
          print_table Sg.describe(stack_security_groups.map(&:physical_resource_id)).map { |s|
            [s.group_name, s.group_id, s.vpc_id, s.description]
          }
        end

        desc 'sg-in ID', 'SG inbound permissions'
        def sg_in(id)
          print_table _sg_permissions(stack_security_group(id).first.ip_permissions)
        end

        desc 'sg-out ID', 'SG outbound permissions'
        def sg_out(id)
          print_table _sg_permissions(stack_security_group(id).first.ip_permissions_egress)
        end

      end
    end

  end
end