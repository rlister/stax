module Stax
  class Stack < Base

    no_commands do
      def import_stacks
        @_import_stacks ||= Aws::Cfn.exports(stack_name).map do |e|
          Aws::Cfn.imports(e.export_name)
        end.flatten.uniq
      end

      def update_warn_imports
        unless import_stacks.empty?
          warn("You may also need to update stacks that import from this one: #{import_stacks.join(',')}")
        end
      end

      def delete_warn_imports
        unless import_stacks.empty?
          warn("The following stacks import from this one: #{import_stacks.join(',')}")
        end
      end
    end

    desc 'imports', 'list imports from this stack'
    def imports
      debug("Stacks that import from #{stack_name}")
      print_table Aws::Cfn.exports(stack_name).map { |e|
        imports = (i = Aws::Cfn.imports(e.export_name)).empty? ? '-' : i.join(',')
        [e.output_key, imports]
      }.sort
    end

  end
end