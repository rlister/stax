module Stax
  module Aws
    class Ec2 < Sdk

      COLORS = {
        running:    :green,
        stopped:    :yellow,
        terminated: :red,
      }

      class << self

        def client
          @_client ||= ::Aws::EC2::Client.new
        end

        ## return instances tagged by stack with name
        def instances(name)
          filter = {name: 'tag:aws:cloudformation:stack-name', values: [name]}
          paginate(:reservations) do |token|
            client.describe_instances(filters: [filter], next_token: token)
          end.map(&:instances).flatten
        end

      end
    end
  end
end