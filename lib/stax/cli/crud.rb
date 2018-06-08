module Stax
  class Cli < Base

    no_commands do
      ## create order: default to stacks from Staxfile, override if needed
      ## delete will be this, in reverse order
      def stack_order
        Stax.stack_list
      end

      def stack_objects
        stack_order.map(&method(:stack))
      end
    end

    desc 'create', 'meta create task'
    def create
      stack_objects.each do |s|
        if s.exists?
          say("Skipping: #{s.stack_name} exists", :yellow)
        elsif y_or_n?("Create #{s.stack_name}?", :yellow)
          s.create
        end
      end
    end

    desc 'update', 'meta update task'
    def update
      stack_objects.each do |s|
        if s.exists?
          y_or_n?("Update #{s.stack_name}?", :yellow) && s.update
        else
          say("#{s.stack_name} does not exist")
        end
      end
    end

    desc 'change', 'meta change task'
    def change
      stack_objects.each do |s|
        if s.exists?
          s.change
        end
      end
    end

    desc 'delete', 'meta delete task'
    def delete
      stack_objects.reverse.each do |s|
        if s.exists?
          s.delete
        else
          say("#{s.stack_name} does not exist", :green)
        end
      end
    end

  end
end