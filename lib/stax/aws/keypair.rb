require 'aws-sdk-ec2'

module Stax
  module Aws
    class Keypair < Sdk

      class << self

        def client
          @_client ||= ::Aws::EC2::Client.new
        end

        def describe(names = nil)
          client.describe_key_pairs(key_names: names).key_pairs
        end

        def create(name)
          client.create_key_pair(key_name: name)
        end

        def delete(name)
          client.delete_key_pair(key_name: name)
        end

      end
    end
  end
end
