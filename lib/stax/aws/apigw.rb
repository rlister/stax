
module Stax
  module Aws
    class APIGateway < Sdk

      class << self

        def client
          @_client ||= ::Aws::APIGateway::Client.new
        end

        def api(id)
          client.get_rest_api(rest_api_id: id)
        end

        def stages(id, deployment = nil)
          client.get_stages(rest_api_id: id, deployment_id: deployment).item
        end

      end

    end
  end
end