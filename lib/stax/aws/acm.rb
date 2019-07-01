module Stax
  module Aws
    class Acm < Sdk

      class << self

        def client
          @_client ||= ::Aws::ACM::Client.new
        end

        def describe(arn)
          client.describe_certificate(certificate_arn: arn)&.certificate
        end

      end

    end
  end
end
