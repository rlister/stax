# Stax

Stax is a highly-opionated framework for managing Cloudformation
stacks along with all the crappy glue code you need around them.

Stax is built as a set of ruby classes, with configuration based
around sub-classing and monkey-patching.

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

```
stack :vpc
stack :db
stack :app
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/stax. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
