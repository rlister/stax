require 'aws-sdk-ecr'
require 'base64'

module Stax
  module Aws
    class Ecr < Sdk

      class << self

        def client
          @_client ||= ::Aws::ECR::Client.new
        end

        def auth
          client.get_authorization_token.authorization_data
        end

        def repositories(opt = {})
          paginate(:repositories) do |next_token|
            client.describe_repositories(opt.merge(next_token: next_token))
          end
        end

        def exists?(repo, tag)
          !client.batch_get_image(repository_name: repo, image_ids: [{image_tag: tag}]).images.empty?
        end

        def login(*registry_ids)
          ids = registry_ids.empty? ? nil : Array(registry_ids)
          client.get_authorization_token(registry_ids: ids).authorization_data
        end

        def images(opt = {})
          paginate(:image_details) do |next_token|
            client.describe_images(opt.merge(next_token: next_token))
          end
        end

      end

    end
  end
end
