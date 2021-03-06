require 'stax/aws/apigw'

module Stax
  module Apigw
    def self.included(thor)
      thor.desc(:apigw, 'API Gateway subcommands')
      thor.subcommand(:apigw, Cmd::Apigw)
    end
  end

  module Cmd
    class Apigw < SubCommand
      stax_info :endpoints, :resources

      no_commands do
        def stack_apis
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::ApiGateway::RestApi')
        end
      end

      desc 'ls', 'list APIS'
      def ls
        print_table stack_apis.map { |r|
          a = Aws::APIGateway.api(r.physical_resource_id)
          [a.name, a.id, a.endpoint_configuration.types.join(','), a.created_date, a.description]
        }
      end

      desc 'stages', 'list API stages'
      def stages
        stack_apis.each do |r|
          api = Aws::APIGateway.api(r.physical_resource_id)
          debug("Stages for API #{api.name} #{api.id}")
          print_table Aws::APIGateway.stages(api.id).map { |s|
            [s.stage_name, s.deployment_id, s.created_date, s.last_updated_date, s.description]
          }
        end
      end

      desc 'resources', 'list resources'
      def resources
        stack_apis.each do |r|
          api = Aws::APIGateway.api(r.physical_resource_id)
          debug("Resources for API #{api.name} #{api.id}")
          print_table Aws::APIGateway.resources(api.id).map { |r|
            methods = r.resource_methods&.keys&.join(',')
            [r.path, r.id, methods]
          }.sort
        end
      end

      desc 'endpoints', 'guess endpoint URIs'
      def endpoints
        stack_apis.each do |r|
          api = Aws::APIGateway.api(r.physical_resource_id)
          debug("Endpoints for API #{api.name} #{api.id}")
          print_table Aws::APIGateway.stages(api.id).map { |s|
            url = "https://#{api.id}.execute-api.#{aws_region}.amazonaws.com/#{s.stage_name}/"
            [s.stage_name, url]
          }.sort
        end
      end

    end
  end
end