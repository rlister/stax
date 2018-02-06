module Stax
  module Aws
    class Route53 < Sdk

      class << self

        def client
          @_client ||= ::Aws::Route53::Client.new
        end

        ## list all zones
        def zones
          client.list_hosted_zones.hosted_zones
        end

        ## list limited number of zones, starting at named zone
        def zones_by_name(name, max_items = nil)
          client.list_hosted_zones_by_name(
            dns_name: name,
            max_items: max_items,
          )&.hosted_zones
        end

        ## get single matching zone, or nil
        def zone_by_name(name)
          zones_by_name(name, 1).find do |zone|
            zone.name == name
          end
        end

        ## record sets for named zone
        def record_sets(opt = {})
          client.list_resource_record_sets(opt)&.resource_record_sets
        end

        def record(name, type = :A)
          zone = name.split('.').last(2).join('.') + '.'
          Aws::Route53.record_sets(
            hosted_zone_id: zone_by_name(zone).id,
            start_record_name: name,
            start_record_type: type,
          ).select do |record|
            (record.name == name) && (record.type == type.to_s)
          end
        end

      end

    end
  end
end