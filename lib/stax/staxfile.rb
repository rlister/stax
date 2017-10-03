module Stax
  def self.load_staxfile
    file = File.join(Dir.pwd, 'Staxfile')
    Stax.class_eval(File.binread(file)) if File.exist?(file)
  end

  ## add a stack by name, creates class as needed
  def self.add_stack(name)
    c = name.capitalize

    ## create the class if it does not exist yet
    if self.const_defined?(c)
      self.const_get(c)
    else
      self.const_set(c, Class.new(Stack))
    end.tap do |klass|
      Cli.desc(name, "#{name} stack")
      Cli.subcommand(name, klass)
    end
  end

  ## add a non-stack command at top level
  def self.add_command(name, klass)
    Cli.desc(name, "#{name} commands")
    Cli.subcommand(name, klass)
  end

end