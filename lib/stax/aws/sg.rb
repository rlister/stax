module Stax
  module Aws
    class Sg < Sdk

      class << self

        def client
          @_client ||= ::Aws::EC2::Client.new
        end

        def describe(ids)
          client.describe_security_groups(group_ids: Array(ids)).security_groups
        end

        def authorize(id, cidr, port = 22)
          client.authorize_security_group_ingress(
            group_id:    id,
            ip_protocol: :tcp,
            from_port:   port,
            to_port:     port,
            cidr_ip:     cidr,
          )
        rescue ::Aws::EC2::Errors::InvalidPermissionDuplicate => e
          warn(e.message)
        end

        def authorize_sg(id, sg, port)
          client.authorize_security_group_ingress(
            group_id: id,
            ip_permissions: [
              {
                ip_protocol: :tcp,
                from_port: port,
                to_port: port,
                user_id_group_pairs: [ { group_id: sg } ],
              }
            ]
          )
        rescue ::Aws::EC2::Errors::InvalidPermissionDuplicate => e
          warn(e.message)
        end

        def revoke(id, cidr, port = 22)
          client.revoke_security_group_ingress(
            group_id:    id,
            ip_protocol: :tcp,
            from_port:   port,
            to_port:     port,
            cidr_ip:     cidr,
          )
        rescue ::Aws::EC2::Errors::InvalidPermissionNotFound => e
          warn(e.message)
        end

        def revoke_sg(id, sg, port)
          client.revoke_security_group_ingress(
            group_id: id,
            ip_permissions: [
              {
                ip_protocol: :tcp,
                from_port: port,
                to_port: port,
                user_id_group_pairs: [ { group_id: sg } ],
              }
            ]
          )
        rescue ::Aws::EC2::Errors::InvalidPermissionNotFound => e
          warn(e.message)
        end
      end
    end
  end
end