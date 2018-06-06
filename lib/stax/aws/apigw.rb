
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

        def resources(id)
          position = nil
          items = []
          loop do
            resp = client.get_resources(rest_api_id: id, position: position)
            items += resp.items
            position = resp.position
            break unless position
          end
          items
        end

      end

    end
  end
end