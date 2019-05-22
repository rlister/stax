module Stax
  module Aws
    class Cloudfront < Sdk

      class << self
        def client
          @_client ||= ::Aws::CloudFront::Client.new
        end

        def distribution(id)
          client.get_distribution(id: id).distribution
        end

        def invalidations(id)
          client.list_invalidations(distribution_id: id).map(&:invalidation_list).map(&:items)
        end

        def invalidation(distribution_id, id)
          client.get_invalidation(distribution_id: distribution_id, id: id).invalidation
        end
      end

    end
  end
end
