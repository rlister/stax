module Stax
  class Stack < Base

    # no_commands do
    #   def self.info(cmds)
    #     puts "info: #{cmds}"
    #   end
    # end

    desc 'info', 'service-specific info'
    def info
      ## get mixins in the order we declared them
      self.class.subcommands.reverse.each do |cmd|
        begin
          invoke cmd, [:info]
        rescue Thor::UndefinedCommandError => e
          # no info no problem
        end
      end
    end

  end
end