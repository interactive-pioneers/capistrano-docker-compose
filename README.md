# Capistrano::Docker::Compose

Docker Compose specific tasks for Capistrano, adding Docker containers to Capistrano code deployments.

## Requirements

- Capistrano 3.5
- Docker Engine 1.11
- Docker Compose 1.7
- HAProxy 1.6

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

Add `capistrano-docker-compose` to `Capfile`:

``` ruby
# Capfile
require 'capistrano/docker/compose'
```

You can configure following Docker Compose specific options in `config/deploy.rb` and/or `config/deploy/<environment>.rb`:

```ruby
# User name when running the Docker image (reflecting Docker's USER instruction)
set :docker_compose_user, '<username>'

# Define port range in respect to load balancer on server
# If 2 or more environments reside on same server, configure port range as per environment
# Ruby's Range object is expected, see http://ruby-doc.org/core-2.3.0/Range.html
set :docker_compose_port_range, <port>..<port>
```

Configure load balancer on server using port range defined in `docker_compose_port_range`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/interactive-pioneers/capistrano-docker-compose. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Licence

Copyright © 2016 Ain Tohvri, Interactive Pioneers GmbH. Licenced under [GPL-3](https://github.com/interactive-pioneers/capistrano-docker-compose/blob/master/LICENSE).
