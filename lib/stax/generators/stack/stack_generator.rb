## generator to create the basic files for one or more new stacks:
##   - add stack to Staxfile
##   - subclass in lib/stack/
##   - cfer/json/yaml template outline in cf/

module Stax
  module Generators
    class StackGenerator < Base
      desc 'Create new stacks with given names.'

      class_option :json, type: :boolean, default: false, desc: 'create json templates'
      class_option :yaml, type: :boolean, default: false, desc: 'create yaml templates'

      def check_args
        abort('List one or more stacks to create') if args.empty?
      end

      def create_staxfile
        create_file 'Staxfile' unless File.exist?('Staxfile')
        append_to_file 'Staxfile' do
          args.map { |s| "stack :#{s}" }.join("\n").concat("\n")
        end
      end

      def create_lib_files
        args.each do |s|
          create_file "lib/stack/#{s}.rb" do
            <<~FILE
            module Stax
              class #{s.capitalize} < Stack
                # include Logs

                # no_commands do
                #   def cfn_parameters
                #     super.merge(
                #       # add parameters as a hash here
                #     )
                #   end
                # end
              end
            end
          FILE
          end
        end
      end

      def create_templates
        if options[:json]
          create_json_templates
        elsif options[:yaml]
          create_yaml_templates
        else
          create_cfer_templates
        end
      end

      private

      def create_cfer_templates
        args.each do |s|
          create_file "cf/#{s}.rb" do
            <<~FILE
            description '#{s} stack'

            # parameter :foo, type: :String, default: ''
            # mappings()
            # include_template()
          FILE
          end
        end
      end

      def create_json_templates
        args.each do |s|
          create_file "cf/#{s}.json" do
            <<~FILE
            {
              "AWSTemplateFormatVersion": "2010-09-09",
              "Description": "#{s} stack",
              "Parameters": {},
              "Mappings": {},
              "Conditions": {},
              "Resources": {},
              "Outputs": {}
            }
          FILE
          end
        end
      end

      def create_yaml_templates
        args.each do |s|
          create_file "cf/#{s}.yaml" do
            <<~FILE
            AWSTemplateFormatVersion: '2010-09-09'
            Description: Stax test stack
            Parameters: {}
            Mappings: {}
            Conditions: {}
            Resources:
            Outputs: {}
          FILE
          end
        end
      end

    end
  end
end