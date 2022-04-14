require 'stax/aws/cloudfront'

module Stax
  module Cloudfront
    def self.included(thor)
      thor.desc('cloudfront COMMAND', 'Cloudfront subcommands')
      thor.subcommand(:cloudfront, Cmd::Cloudfront)
    end
  end

  module Cmd
    class Cloudfront < SubCommand
      stax_info :ls

      COLORS = {
        Enabled:   :green,
        Disabled:  :red,
        Completed: :green,
      }

      no_commands do
        def stack_cloudfront_distributions
          @_stack_cloudfront_distributions ||= Aws::Cfn.resources_by_type(my.stack_name, 'AWS::CloudFront::Distribution')
        end

        def stack_cloudfront_ids
          stack_cloudfront_distributions.map(&:physical_resource_id)
        end
      end

      desc 'ls', 'list cloudfront distributions for stack'
      def ls
        debug("Cloudfront distributions for #{my.stack_name}")
        print_table stack_cloudfront_ids.map { |id|
          d = Aws::Cloudfront.distribution(id)
          [
            d.id,
            d.domain_name,
            d.status,
            color(d.distribution_config.enabled ? :Enabled : :Disabled, COLORS),
            d.last_modified_time,
          ]
        }
      end

      desc 'domains', 'list cloudfront domains'
      def domains
        puts stack_cloudfront_ids.map { |id|
          Aws::Cloudfront.distribution(id).domain_name
        }
      end

      desc 'invalidations', 'list invalidations for distributions'
      def invalidations
        stack_cloudfront_ids.each do |id|
          debug("Invalidations for distribution #{id}")
          Aws::Cloudfront.invalidations(id).each { |list|
            print_table list.map { |inv|
              i = Aws::Cloudfront.invalidation(id, inv.id)
              [ i.id, color(i.status, COLORS), i.create_time ]
            }
          }
        end
      end

      ## https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/viewing-cloudfront-metrics.html#monitoring-console.distributions-additional
      ## this is not supported by cfn, see:
      ## https://github.com/aws-cloudformation/cloudformation-coverage-roadmap/issues/545
      desc 'monitoring', 'control monitoring subscriptions'
      method_option :enable,  aliases: '-e', type: :boolean, description: 'enable additional metrics'
      method_option :disable, aliases: '-d', type: :boolean, description: 'disable additional metrics'
      def monitoring
        client = Aws::Cloudfront.client
        stack_cloudfront_ids.each do |id|
          debug("Cloudfront monitoring for distribution #{id}")
          if options[:enable]
            sub = { realtime_metrics_subscription_config: { realtime_metrics_subscription_status: :Enabled } }
            resp = client.create_monitoring_subscription(distribution_id: id, monitoring_subscription: sub)
            puts resp.monitoring_subscription.realtime_metrics_subscription_config&.realtime_metrics_subscription_status
          elsif options[:disable]
            puts 'deleting subscription'
            client.delete_monitoring_subscription(distribution_id: id)
          else
            cfg = client.get_monitoring_subscription(distribution_id: id)&.monitoring_subscription&.realtime_metrics_subscription_config
            puts "current status: #{cfg&.realtime_metrics_subscription_status}"
          end
        end
      end

    end

  end
end
