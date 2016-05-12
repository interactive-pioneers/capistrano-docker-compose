# Capistrano::Docker::Compose

Docker Compose specific tasks for Capistrano. It adds Docker containers to Capistrano code deployments.

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

    # Capfile
    require 'capistrano/docker/compose'

You can configure following Docker Compose specific options in `config/deploy.rb`:

    # User name when running the Docker image (reflecting Docker's USER instruction)
    set :docker_compose_user, '<username>'

    # Define port range in respect to load balancer on server
    set :docker_compose_port_range, <port>..<port>

Configure load balancer on server using port range defined in `docker_compose_port_range`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/interactive-pioneers/capistrano-docker-compose. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
