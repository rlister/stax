require 'aws-sdk-lambda'

module Stax
  module Aws
    class Lambda < Sdk

      class << self

        def client
          @_client ||= ::Aws::Lambda::Client.new
        end

        def list
          paginate(:functions) do |marker|
            client.list_functions(marker: marker)
          end
        end

        def configuration(name)
          client.get_function_configuration(function_name: name)
        end

        def code(name)
          client.get_function(function_name: name).code.location
        end

        def invoke(opt)
          client.invoke(opt)
        end

        def update_code(opt)
          client.update_function_code(opt)
        end

      end

    end
  end
end
