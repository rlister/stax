require 'aws-sdk-secretsmanager'

module Stax
  module Aws
    class SecretsManager < Sdk

      class << self

        def client
          @_client ||= ::Aws::SecretsManager::Client.new
        end

        def list
          client.list_secrets.map(&:secret_list).flatten
        end

        def get(id, version = :AWSCURRENT)
          client.get_secret_value(secret_id: id, version_stage: version)
        end

      end
    end
  end
end
