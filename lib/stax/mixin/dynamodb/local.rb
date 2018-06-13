require 'json'

module Stax
  module Cmd
    class DynamoDB < SubCommand

      no_commands do

        ## client for dynamodb-local endpoint
        def client
          @_client ||= ::Aws::DynamoDB::Client.new(endpoint: 'http://localhost:8000')
        end

        ## get CFN template and return hash of table configs
        def dynamo_local_tables
          JSON.parse(my.cfn_template).fetch('Resources', {}).select do |_, v|
            v['Type'] == 'AWS::DynamoDB::Table'
          end
        end

        ## convert some CFN properties to their SDK equivalents
        def dynamo_payload_from_template(id, template)
          template['Properties'].tap do |p|
            p['TableName'] ||= id # use logical id if no name in template
            p['StreamSpecification']&.merge!( 'StreamEnabled' => true )
            p['SSESpecification'] &&= { 'Enabled' => p.dig('SSESpecification', 'SSEEnabled') }
            p.delete('TimeToLiveSpecification')
            p.delete('Tags')
          end
        end

        ## monkey-patch this method to apply any app-specific changes to payload
        ## args: logical_id, payload hash
        ## returns: new payload
        def dynamo_payload_hacks(id, payload)
          payload
        end

        ## convert property names to ruby SDK form
        def dynamo_ruby_payload(payload)
          payload&.deep_transform_keys do |key|
            key.to_s.underscore.to_sym
          end
        end

        ## create table
        def dynamo_local_create(payload)
          client.create_table(dynamo_ruby_payload(payload))
        rescue ::Aws::DynamoDB::Errors::ResourceInUseException => e
          warn(e.message)       # table exists
        rescue Seahorse::Client::NetworkingError => e
          warn(e.message)       # dynamodb-local probably not running
        end
      end

      desc 'local', 'create local tables from template'
      method_option :tables,  aliases: '-t', type: :array,   default: nil,   desc: 'filter table ids'
      method_option :payload, aliases: '-p', type: :boolean, default: false, desc: 'just output payload'
      def local
        tables = dynamo_local_tables
        tables.slice!(*options[:tables]) if options[:tables]

        tables.each do |id, value|
          payload = dynamo_payload_from_template(id, value)
          payload = dynamo_payload_hacks(id, payload) # apply user-supplied hacks
          if options[:payload]
            puts JSON.pretty_generate(payload)
          else
            puts "create table #{id}"
            dynamo_local_create(payload)
          end
        end
      end

    end
  end
end