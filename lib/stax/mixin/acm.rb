require 'stax/aws/acm'

module Stax
  module Acm
    def self.included(thor)
      thor.desc('acm COMMAND', 'ACM subcommands')
      thor.subcommand(:acm, Cmd::Acm)
    end
  end

  module Cmd
    class Acm < SubCommand

      COLORS = {
        SUCCESS:            :green,
        PENDING_VALIDATION: :yellow,
      }

      no_commands do
        def stack_acm_certs
          Aws::Cfn.resources_by_type(my.stack_name, 'AWS::CertificateManager::Certificate')
        end

        def route53_change_batch(record)
          {
            Comment: 'validation',
            Changes: [
              {
                Action: :UPSERT,
                ResourceRecordSet: {
                  Name: record.name,
                  Type: record.type,
                  TTL: 300,
                  ResourceRecords: [ {Value: record.value} ]
                }
              }
            ]
          }.to_json
        end
      end

      desc 'ls', 'list ACM certs'
      def ls
        print_table stack_acm_certs.map { |r|
          c = Aws::Acm.describe(r.physical_resource_id)
          in_use = c.in_use_by.empty? ? 'not in use' : 'in use'
          [ c.domain_name, color(c.status, COLORS), c.issuer, in_use, c.created_at ]
        }
      end

      desc 'domains', 'list domains for certs'
      def domains
        stack_acm_certs.each do |r|
          c = Aws::Acm.describe(r.physical_resource_id)
          debug("Domains for #{c.certificate_arn}")
          print_table c.domain_validation_options.map { |d|
            [ d.domain_name, color(d.validation_status, COLORS), d.validation_method ]
          }
        end
      end

      desc 'validation', 'list pending validation records for certs'
      method_option :cli, type: :boolean, default: false, desc: 'show aws cli command for route53 change'
      def validation
        stack_acm_certs.each do |r|
          c = Aws::Acm.describe(r.physical_resource_id)
          c.domain_validation_options.each do |d|
            next if d.validation_status == 'SUCCESS'
            debug("Pending validation for #{d.domain_name}")
            if options[:cli]
              puts "aws route53 change-resource-record-sets --change-batch '#{route53_change_batch(d.resource_record)}' --hosted-zone-id ..."
            else
              puts([d.resource_record.name, d.resource_record.type, d.resource_record.value].join(' '))
            end
          end
        end
      end

    end
  end
end
