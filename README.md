# Stax

Stax is a highly-opionated framework for managing Cloudformation
stacks along with all the crappy glue code you need around them.

Stax is built as a set of ruby classes, with configuration based
around sub-classing and monkey-patching.

Stax can read template files written in `yaml`, `json` or the
[cfer](https://github.com/seanedwards/cfer) ruby wrapper. It will
choose which to use based on file extensions found.

## Getting Started

Install `stax`:

```sh
gem install stax
```

Create a new `stax` application. You can choose to do this in an
ops-specific subdirectory of your application code (thus delivering
infrastructure to run an app with the app itself), or create an
infrastructure-specific repo. It's up to you.

```sh
stax new ops
```

Change to your stax directory and install bundle:

```sh
cd ops
bundle install
```

Create an example stack, and add a resource:

```sh
stax g stack example
cat >> cf/example.rb
resource :s3, 'AWS::S3::Bucket'
^D
stax example create
```

Your new stack should create, and you should now be able to list it,
inspect resource, etc:

```sh
stax ls
stax example resources
```

Delete your example stack:

```sh
stax example delete
```

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

```
cd ops
bundle
bundle exec stax version
```

## Usage

Add each of your stacks to `ops/Staxfile`:

```ruby
stack :vpc
stack :db
stack :app
```

Run stax to see it has created subcommands for each of your stacks:

```
bundle exec stax
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

```
bundle exec stax vpc
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

```sh
stax vpc create
stax vpc update
stax vpc delete
```

By default Stax will name stacks as `$app-$branch-$stack`. For our
example we will have e.g. `website-master-vpc`, `website-master-db`,
etc.

To change this scheme modify the methods `Stax::Base::stack_prefix`
and/or `Stax::Stack::stack_name`.

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
