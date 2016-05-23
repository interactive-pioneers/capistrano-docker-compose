# Rewire key commands to container
%i(bundle rake).map do |command|
  # FIXME: replace hard-coded web service with master service setting
  # https://github.com/interactive-pioneers/capistrano-docker-compose/issues/7
  SSHKit.config.command_map.prefix[command].push("docker-compose exec web")
end

namespace :deploy do

  set :previous_release_path, nil

  task :pull_images do
    on roles(fetch(:docker_compose_roles)) do
      within release_path do
        execute :'docker-compose', 'pull'
        # TODO: confirm successful pull
      end
    end
  end

  task :start_containers do
    on roles(fetch(:docker_compose_roles)) do
      set :previous_release_path, previous_release
      within release_path do
        with cap_docker_compose_root_path: fetch(:deploy_to), cap_docker_compose_port: detect_available_port do
          execute :'docker-compose', '-f', "docker-compose-#{fetch(:rails_env)}.yml", 'up', '-d'
        end
      end
    end
  end

  task :claim_files_by_container do
    user = fetch(:docker_compose_user)
    unless user.nil?
      on roles(fetch(:docker_compose_roles)) do
        within release_path do
          execute :'docker-compose', 'exec', 'web', 'chown', '-R', "#{user}:#{user}", '.'
        end
      end
    end
  end

  task :purge_old_containers do
    on roles(fetch(:docker_compose_roles)) do
      if fetch(:previous_release_path)
        info "Purging previous release containers at #{fetch(:previous_release_path)}"
        within fetch(:previous_release_path) do
          execute :'docker-compose', 'down'
        end
      end
    end
  end

  # docker-compose down is not removing used networks
  # and therefore exclusive removal is required.
  # See https://github.com/docker/compose/issues/2279
  #
  task :purge_old_networks do
    on roles(fetch(:docker_compose_roles)) do
      begin
        previous_release = Pathname.new(fetch(:previous_release_path)).basename
        execute :docker, 'network', 'rm', "#{previous_release}_default"
      rescue
        warn "Failed to remove previously used network! Consider removing manually on server with: docker network rm <network>"
      end
    end
  end

  task :purge_failed_containers do
    on roles(fetch(:docker_compose_roles)) do
      within release_path do
        execute :'docker-compose', 'down'
      end
    end
  end

  def detect_available_port
    ports = fetch(:docker_compose_port_range)
    ports.each do |port|
      # TODO: Mac-compliant port check.
      port_response = capture("netstat -lnt | awk '$6 == \"LISTEN\" && $4 ~ \".#{port}\"'")
      if port_response.empty?
        info "Port #{port} of #{ports.to_s} is free"
        return port
      end
    end
    raise "No port available in range #{ports.to_s}. Deployment aborted."
  end

  def previous_release
    path = "#{fetch(:deploy_to)}/current"
    if test("[ -L #{path} ]")
      return capture("readlink -f #{path}")
    end
    return nil
  end

  after :updating, :pull_images
  after :updating, :start_containers
  before :publishing, :claim_files_by_container
  after :failed, :purge_failed_containers
  after :finished, :purge_old_containers
  after :finished, :purge_old_networks

end

namespace :load do
  task :defaults do
    set :docker_compose_roles, fetch(:docker_compose_roles, :all)
  end
end
