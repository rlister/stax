module Stax
  @@_root_path = nil
  @@_stack_list = []

  ## the stax root is defined as location of Staxfile
  def self.root_path
    @@_root_path
  end

  ## list of stacks defined in Staxfile
  def self.stack_list
    @@_stack_list
  end

  ## search up the dir tree for nearest Staxfile
  def self.find_staxfile
    Pathname.pwd.ascend do |path|
      return path if File.exist?(file = path.join('Staxfile'))
    end
  end

  def self.load_staxfile
    @@_root_path = find_staxfile
    if root_path
      load(root_path.join('Staxfile'))
      require_stacks
    end
  end

  ## auto-require any stack lib files
  def self.require_stacks
    stack_list.each do |stack|
      f = root_path.join('lib', 'stack', "#{stack}.rb")
      require(f) if File.exist?(f)
    end
  end

  ## add a stack by name, creates class as needed
  def self.add_stack(name, opt = {})
    @@_stack_list << name

    ## camelize the stack name into class name
    c = name.to_s.split(/[_-]/).map(&:capitalize).join

    ## create the class if it does not exist yet
    if self.const_defined?(c)
      self.const_get(c)
    else
      self.const_set(c, Class.new(Stack))
    end.tap do |klass|
      Cli.desc("#{name} COMMAND", "#{name} stack commands")
      Cli.subcommand(name, klass)

      ## syntax to include mixins, reverse to give predictable include order
      opt.fetch(:include, []).reverse.each do |i|
        klass.include(self.const_get(i))
      end

      klass.instance_variable_set(:@name, name)
      klass.instance_variable_set(:@imports, Array(opt.fetch(:import, [])))
      klass.instance_variable_set(:@type, opt.fetch(:type, nil))
      klass.instance_variable_set(:@groups, opt.fetch(:groups, nil))
    end
  end

  ## add a non-stack command at top level
  def self.add_command(name, klass = nil)
    ## class defaults to eg Stax::Name::Cmd
    klass ||= self.const_get(name.to_s.split(/[_-]/).map(&:capitalize).join + '::Cmd')

    Cli.desc(name, "#{name} commands")
    Cli.subcommand(name, klass)
  end

end
