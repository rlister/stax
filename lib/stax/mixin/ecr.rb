require 'stax/aws/ecr'

module Stax
  module Ecr
    def self.included(thor)
      thor.desc(:ecr, 'ECR subcommands')
      thor.subcommand(:ecr, Cmd::Ecr)
    end

    def ecr_repositories
      @_ecr_repositories ||= Aws::Cfn.resources_by_type(stack_name, 'AWS::ECR::Repository')
    end

    def ecr_repository_names
      @_ecr_repository_names ||= ecr_repositories.map(&:physical_resource_id)
    end

    ## override to set an explicit repo name
    def ecr_repository_name
      @_ecr_repository_name ||= (ecr_repository_names&.first || app_name)
    end
  end

  module Cmd
    class Ecr < SubCommand

      desc 'repositories', 'list ECR repositories'
      def repositories
        print_table Aws::Ecr.repositories(repository_names: my.ecr_repository_names).map { |r|
          [r.repository_name, r.repository_uri, r.created_at]
        }
      end

      desc 'images', 'list ECR images'
      method_option :repositories, aliases: '-r', type: :array, default: nil, desc: 'list of repos'
      def images
        (options[:repositories] || my.ecr_repository_names).each do |repo|
          debug("Images in repo #{repo}")
          print_table Aws::Ecr.images(repository_name: repo).map { |i|
            [i.image_tags.join(' '), i.image_digest, human_bytes(i.image_size_in_bytes), i.image_pushed_at]
          }
        end
      end

    end
  end

end