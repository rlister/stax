module Stax

  ## search up the dir tree for nearest Staxfile
  def self.load_staxfile
    file = nil
    Pathname.pwd.ascend do |path|
      if File.exist?(f = File.join(path, 'Staxfile'))
        file = f
        break
      end
    end
    load(file) if file
  end

  ## add a stack by name, creates class as needed
  def self.add_stack(name, opt = {})
    c = name.capitalize

    ## create the class if it does not exist yet
    if self.const_defined?(c)
      self.const_get(c)
    else
      self.const_set(c, Class.new(Stack))
    end.tap do |klass|
      Cli.desc(name, "#{name} stack")
      Cli.subcommand(name, klass)

      ## has syntax to include mixins
      opt.fetch(:include, []).each do |i|
        klass.include(self.const_get(i))
      end
    end
  end

  ## add a non-stack command at top level
  def self.add_command(name, klass)
    Cli.desc(name, "#{name} commands")
    Cli.subcommand(name, klass)
  end

end