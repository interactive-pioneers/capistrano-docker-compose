# Capistrano::Docker::Compose [![Build Status](https://travis-ci.org/interactive-pioneers/capistrano-docker-compose.svg?branch=master)](https://travis-ci.org/interactive-pioneers/capistrano-docker-compose) [![Gem Version](https://badge.fury.io/rb/capistrano-docker-compose.svg)](https://badge.fury.io/rb/capistrano-docker-compose)

Docker Compose specific tasks for Capistrano allowing seamless zero downtime containerised deployments.

## Minimum requirements

- Capistrano 3.5
- Docker Engine 1.11
- Docker Compose 1.7
- HAProxy 1.6

## Supported databases

| Database    | Versions tested |
| --------    | --------------- |
| PostgreSQL  | 9.5             |
| MariaDB     | 5.5             |

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'capistrano-docker-compose'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-docker-compose

## Usage

Create Docker Compose descriptors for each environment leaving `docker-compose.yml` as default for development environment, e.g.:

  - `docker-compose.yml`
  - `docker-compose-staging.yml`
  - `docker-compose-production.yml`

Make Compose YAML with `web` service (name is conventional) using following environment variables:

- `CAP_DOCKER_COMPOSE_ROOT_PATH` for shared path
- `CAP_DOCKER_COMPOSE_PORT` for port range

If you're using database service with migrations in Ruby on Rails, make sure to name database service as `db` (name is conventional).

See also [Compose YAML example](https://github.com/interactive-pioneers/capistrano-docker-compose/blob/master/docker-compose-staging.example.yml).

Add `capistrano-docker-compose` to `Capfile`:

``` ruby
# Capfile
require 'capistrano/docker/compose'
```

Configure following Docker Compose specific options in `config/deploy.rb` and/or `config/deploy/<environment>.rb`:

```ruby
# Define port range in respect to load balancer on server
# If 2 or more environments reside on same server, configure port range as per environment
# Ruby's Range object is expected, see http://ruby-doc.org/core-2.3.0/Range.html
# Example: set :docker_compose_port_range, 2070..2071
set :docker_compose_port_range, <port>..<port>

# OPTIONAL
# User name when running the Docker image (reflecting Docker's USER instruction)
# Example: set :docker_compose_user, 'pioneer'
set :docker_compose_user, '<username>'

# OPTIONAL
# Roles considered
# Defaults to :all
# Example: set :docker_compose_roles, :web
set :docker_compose_roles, <roles>
```

Configure load balancer with port range defined in `docker_compose_port_range`, see [example configuration](https://github.com/interactive-pioneers/capistrano-docker-compose/blob/master/haproxy.example.cfg).

NB! Ensure load balancer's HTTP health check uses Layer 7 and corresponds to the needs of the particular application.

### PHP projects

To use `capistrano-docker-compose` on PHP project, such as Wordpress or Drupal:

1. Add `Gemfile` to project root:

	```ruby
	# Gemfile
	source 'https://rubygems.org'

	group :capistrano do
		gem 'capistrano-bundler'
		gem 'capistrano-docker-compose'
	end
	```
2. Run `bundle` to install

If bundling is not desired during deployment (no RubyGems dependencies), Capistrano flow can be altered by removing bundler task:

```ruby
# config/deploy.rb
namespace :deploy do
  Rake::Task["bundler:install"].clear_actions
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/interactive-pioneers/capistrano-docker-compose. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Licence

Copyright © 2016 Ain Tohvri, Interactive Pioneers GmbH. Licenced under [GPL-3](https://github.com/interactive-pioneers/capistrano-docker-compose/blob/master/LICENSE).
