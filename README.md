# jenkins-builder

`jenkins-builder` is a gem for submit jenkins building tasks from command line.

## Requirements

  1. This gem uses macOS KeyChain for managing credentials for logging into jenkins website, so macOS is the only supported OS by now.
  2. It use the `fzf` fuzzy selecting utility to filter jenkins job names and git branches, so before using this gem, you should install `fzf` first: `brew install fzf`.

## Installation

    $ gem install jenkins-builder
    
If any permission errors occurs, prepend `sudo`:

    $ sudo gem install jenkins-builder

## Usage

### Getting help information

    $ jk help
    
### Setup

All configuration stores in `$HOME/.jenkins-builder.yaml` except password.

Password stores in macOS KeyChain, KeyChain service name is `jenkins-builder-credentials`.

#### Setup URL and credentials interactively

Just run: `$ jk setup`

#### Show settings information

    $ jk info
    
By default, password will not be shown, but if you want:  `$ jk info -p`

#### Edit config file directly

    # jk setup -e
    
### Build

#### Specify job identifiers as command line arguments

    $ jk build project1 project2 ...
    
#### Fail-Fast

If multiple jobs are specified, all jobs will be built by default. If yout wanna cancel all subsequent jobs after some job failed, use `-f` option of `build` command:

    # jk build -f project1 project2 ...

#### Specify git brand if you use mbranch plugin

    $ jk build project:origin/develop project2:origin/master ...
    
#### Suppress console output of build

    $ jk build -s project1 ...
    
#### Use fzf to filter job names (project names) or git branch names

Just run `jk build` without job identifiers specified as command line arguments:

    $ jk build

Or even just (because `build` is the default task):

    $ jk

### Alias

For most common used jobs, you can create aliases for them for convenience.

#### Create an alias

    $ jk alias p1 'build project1:origin/develop'

then you could just run:

    $ jk p1
    
it's equivalent to run `jk build project1:origin/develop`

#### List aliases

    $ jk alias
    
#### Delete an alias

    $ jk unalias p1
    
### Hooks

You can add hooks into configuration, which will be executed after a job build finished, the console output will be sent to the hook process as STDIN. See Config Example.


### Config Example

```
---
url: http://jenkins.example.com
username: lululau
branches:
- origin/develop
- origin/staging
- origin/master
aliases:
  kd: build kubernetes:origin/develop
  km: build kubernetes:origin/master
  lc: build linux_core
hooks:
  linux_core: "ssh my_server 'cd /var/logs/ && tail -f $(ls -t | head -1)'"
  kubernetes: "/my/local/machine/clean.sh"
jobs-cache:
  expire: '2018-12-16 11:25:11'
  jobs:
  - kubernetes 
  - linux_core
  - my_e_shop
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lululau/jenkins-builder. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Jenkins::Builder project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/lululau/jenkins-builder/blob/master/CODE_OF_CONDUCT.md).
