module Stax
  def self.load_staxfile
    file = File.join(Dir.pwd, 'Staxfile')
    Stax.class_eval(File.binread(file)) if File.exist?(file)
  end

  ## add a Stack subclass as a thor subcommand
  def self.add_stack(name)
    c = name.capitalize

    ## create the class if it does not exist yet
    klass = self.const_defined?(c) ? self.const_get(c) : self.const_set(c, Class.new(Stack))

    ## create thor subcommand
    Cli.desc(name, "control #{name} stack")
    Cli.subcommand(name, klass)

    ## return the class
    klass
  end
end