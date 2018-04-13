module Stax
  @@_stack_list = []

  ## list of stacks defined in Staxfile
  def self.stack_list
    @@_stack_list
  end

  ## try to require file from lib/stack/ for each stack
  def self.auto_require(path)
    stack_list.each do |stack|
      f = path.join('lib', 'stack', "#{stack}.rb")
      require(f) if File.exist?(f)
    end
  end

  ## search up the dir tree for nearest Staxfile
  def self.load_staxfile
    Pathname.pwd.ascend do |path|
      if File.exist?(file = path.join('Staxfile'))
        load(file) if file
        auto_require(path)
        break
      end
    end
  end

  ## add a stack by name, creates class as needed
  def self.add_stack(name, opt = {})
    @@_stack_list << name
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

      klass.instance_variable_set(:@imports, Array(opt.fetch(:import, [])))
    end
  end

  ## add a non-stack command at top level
  def self.add_command(name, klass)
    Cli.desc(name, "#{name} commands")
    Cli.subcommand(name, klass)
  end

end