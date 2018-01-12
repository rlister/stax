require 'stax/aws/ec2'

module Stax
  module Ec2
    def self.included(thor)
      thor.desc(:ec2, 'EC2 subcommands')
      thor.subcommand(:ec2, Cmd::Ec2)
    end
  end

  module Cmd
    class Ec2 < SubCommand
      COLORS = {
        ## instances
        running:    :green,
        stopped:    :yellow,
        terminated: :red,
        ## images
        available: :green,
        pending:   :yellow,
        failed:    :red,
      }

      desc 'ls', 'list instances for stack'
      def ls
        print_table Aws::Ec2.instances(my.stack_name).map { |i|
          name = i.tags.find { |t| t.key == 'Name' }&.value
          [
            name,
            i.instance_id,
            i.instance_type,
            i.placement.availability_zone,
            color(i.state.name, COLORS),
            i.private_ip_address,
            i.public_ip_address
          ]
        }
      end

      desc 'images', 'list AMI images'
      method_option :owners,   aliases: '-o', type: :array,   default: %w[self], desc: 'self, amazon, aws-marketplace, microsoft'
      method_option :name,     aliases: '-N', type: :array,   default: nil,      desc: 'names of AMIs to list'
      method_option :image_id, aliases: '-i', type: :array,   default: nil,      desc: 'image IDs to list'
      method_option :tag,      aliases: '-t', type: :array,   default: nil,      desc: 'tags as key=value'
      method_option :tag_key,  aliases: '-T', type: :array,   default: nil,      desc: 'tag keys that should exist'
      method_option :state,    aliases: '-s', type: :array,   default: nil,      desc: 'available, pending, failed'
      method_option :number,   aliases: '-n', type: :numeric, default: nil,      desc: 'number of most recent to return'
      def images
        filters = [
          {name: :name,      values: options[:name]},
          {name: :state,     values: options[:state]},
          {name: 'image-id', values: options[:image_id]},
          {name: 'tag-key',  values: options[:tag_key]},
          options[:tag]&.map do |tag|
            k, v = tag.split('=')
            {name: "tag:#{k}", values: [v]}
          end
        ].flatten.reject{ |f| f&.fetch(:values).nil? }

        images = Aws::Ec2.images(owners: options[:owners], filters: filters.empty? ? nil : filters)
        images = images.last(options[:number]) if options[:number]

        print_table images.map { |i|
          tags = i.tags.map{ |t| "#{t.key}=#{t.value}" }.sort.join(',')
          [ i.name, i.image_id, i.root_device_type, color(i.state, COLORS), i.creation_date, tags ]
        }
      end
    end

  end
end