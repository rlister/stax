module Stax
  class SubCommand < Base

    class << self
      def stax_info(*tasks)
        @stax_info_tasks ||= []
        @stax_info_tasks += tasks
      end

      def stax_info_tasks
        @stax_info_tasks&.uniq
      end
    end

    no_commands do
      ## return the Stack instance that called this subcommand
      def my
        @_my ||= stack(current_command_chain.first)
      end
    end

    desc 'info', 'stax info task', hide: true
    def info
      self.class.stax_info_tasks&.each do |task|
        begin
          invoke task
          puts "\n"
        rescue NoMethodError => e
          warn(e.message)
        end
      end
    end

  end
end