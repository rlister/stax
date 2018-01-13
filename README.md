# Stax

Stax is a highly-opionated framework for managing Cloudformation
stacks along with all the crappy glue code you need around them.

Stax is built as a set of ruby classes, with configuration based
around sub-classing and monkey-patching.

For now, Stax reads template files written using the
[cfer](https://github.com/seanedwards/cfer) ruby wrapper. It should be
straightforward to change to raw json/yaml, or a different wrapper by
re-implementing the methods in `lib/stax/stack/crud.rb`.

## Concepts

### Application

You have an application in a git repo. Our example will be called
`website`. The Stax infrastructure code and cloudformation templates
live in the same repo as the application code.

### Branch

You can check out any branch of your repo and deploy a
fully-operational infrastructure using Stax.

Example branches might be `prod`, `stg`, `dev`, or perhaps your model
is `release/37`, `feature/38`, `hotfix/1234`, etc.

### Stacks

Each deployable branch consists of one or more actual cloudformation
stacks. For example, our website app may consist of stacks `vpc`, `db`
and `app`.

In our experience it is better to build multiple coupled
cloudformation stacks, handling discrete parts of an application
infrastructure, rather than having a single giant template.

These stacks are connected via their outputs and input parameters. For
example, `vpc` stack outputs its subnet IDs, which are passed as
parameters to the `app` stack. Stax is designed to handle this wiring
for us.

### Extensions

Stax is intended to be modified to handle all the hackery needed in
real-world app deployments. Each stack is modeled by subclassing the
`Stax::Stack` class, and you are encouraged to monkey-patch methods,
for example to perform extra work before/after creating or destroying
stacks.

## Installation

We like to keep all infrastructure code in a subdirectory `ops` of
application repos, but you can use any layout you like.

Example directory structure:

```
ops/
├── Gemfile
├── Staxfile
├── cf/
├── lib/
```

Add this line to your `ops/Gemfile`:

```ruby
gem 'stax'
```

And then execute:

```bash
$ cd ops
$ bundle
$ bundle exec stax version
```

## Usage

Add each of your stacks to `ops/Staxfile`:

```ruby
stack :vpc
stack :db
stack :app
```

Run stax to see it has created subcommands for each of your stacks:

```bash
$ bundle exec stax
Commands:
  stax app             # app stack
  stax create          # meta create task
  stax db              # db stack
  stax delete          # meta delete task
  stax help [COMMAND]  # Describe available commands or one specific command
  stax ls              # list stacks for this branch
  stax version         # show version
  stax vpc             # vpc stack

```

with the standard create/update/delete tasks for each:

```bash
$ bundle exec stax vpc
Commands:
  stax vpc create           # create stack
  stax vpc delete           # delete stack
  stax vpc events           # show all events for stack
  stax vpc exists           # test if stack exists
  stax vpc generate         # generate cloudformation template
  stax vpc help [COMMAND]   # Describe subcommands or one specific subcommand
  stax vpc id [LOGICAL_ID]  # get physical ID from resource logical ID
  stax vpc outputs          # show stack outputs
  stax vpc parameters       # show stack input parameters
  stax vpc protection       # show/set termination protection for stack
  stax vpc resources        # list resources for this stack
  stax vpc tail             # tail stack events
  stax vpc template         # get template of existing stack from cloudformation
  stax vpc update           # update stack
```

## Cloudformation templates

Stax will load template files from the path relative to its `Staxfile`
as `cf/$stack.rb`, e.g. `cf/vpc.rb`. Modify this using the method `Stax::Stack::cfer_template`.
See `examples` for a typical setup.

Simply control stacks using the relevant subcommands:

```bash
$ stax vpc create
$ stax vpc update
$ stax vpc delete
```

## Stack parameters

For any given stack, subclass `Stax::Stack` and return define a hash of
parameters from the method `cfer_parameters`. For example:

```ruby
module Stax
  class App < Stack
    no_commands do

      def cfer_parameters
        {
          vpc: stack(:vpc).stack_name,  # how to reference other stacks
          db:  stack(:db).stack_name,
          ami: 'ami-e582d29f',
        }
      end

    end
  end
end
```

Note, `Stax::Stack` objects are subclassed from
[Thor](https://github.com/erikhuda/thor), and any non-CLI command
methods must be defined inside a `no_commands` block. See examples for
clearer illustration of this.

## Adding and modifying tasks

A strong underlying assumption of Stax is that you will always need
extra non-cloudformation glue code to handle edge-cases in your
infrastructure. This is handled by sub-classing and monkey-patching
`Stax::Stack`.

For example, in our `Stax::App` class:

```ruby
module Stax
  class App < Stack

    desc 'create', 'create stack'
    def create
      ensure_stack :vpc, :db   # make sure vpc and db stacks are created first
      super                    # create the stack
      notify_slack()           # define and call any extra code you need
    end

    desc 'delete', 'delete stack'
    def delete
      super                    # delete the stack
      cleanup_code()           # do some extra work
      notify_slack()           # etc
    end

  end
end
```

## Development

After checking out the repo, run `bin/setup` to install
dependencies. You can also run `bin/console` for an interactive prompt
that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake
install`. To release a new version, update the version number in
`version.rb`, and then run `bundle exec rake release`, which will
create a git tag for the version, push git commits and tags, and push
the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/[USERNAME]/stax. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected
to adhere to the [Contributor
Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).
