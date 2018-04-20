module Stax
  class Stack < Base

    no_commands do
      def warn_imports
        imports = Aws::Cfn.exports(stack_name).map do |e|
          Aws::Cfn.imports(e.export_name)
        end.flatten.uniq

        unless imports.empty?
          warn("You may also need to update stacks that import from this one: #{imports.join(',')}")
        end
      end
    end

    desc 'imports', 'list imports from this stack'
    def imports
      debug("Stacks that import from #{stack_name}")
      print_table Aws::Cfn.exports(stack_name).map { |e|
        imports = (i = Aws::Cfn.imports(e.export_name)).empty? ? '-' : i.join(',')
        [e.output_key, imports]
      }
    end

  end
end