# Rewire key commands to container
%i(bundle rake).map do |command|
  # FIXME: replace hard-coded web service with master service setting
  # https://github.com/interactive-pioneers/capistrano-docker-compose/issues/7
  # FIXME: restore command execution on login shell once SSHKit allows command map suffixes
  # https://github.com/capistrano/sshkit/issues/366
  SSHKit.config.command_map.prefix[command].push("docker-compose exec web")
end

namespace :deploy do

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
          # Give services 3s to come up
          # TODO: implement flexibly into options
          sleep 3
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
      if fetch(:previous_release_path, false)
        info "Purging previous release containers at #{fetch(:previous_release_path)}"

        # TODO: use to docker-compose pause
        #release_name = Pathname.new(release_path).basename.to_s
        #web_container_id = capture("docker ps -q --filter 'name=#{release_name}_web'")
        #execute :docker, 'pause', web_container_id


        #within release_path do
          #execute :'docker-compose', 'start', 'db'
          #execute :'docker-compose', 'unpause', 'web'
          #sleep 1
        #end

        within fetch(:previous_release_path) do
          containers = capture :'docker-compose', 'ps', '-q'
          unless containers.empty?
            execute :'docker-compose', 'unpause', 'web'
            execute :'docker-compose', 'down'
          end
        end

        #db_container_id = capture("docker ps -q --filter 'name=#{release_name}_db'")
        #execute :docker, 'restart', db_container_id

        # Give services 3s to come up
        # TODO: implement flexibly into options
        #sleep 3

        #execute :docker, 'unpause', web_container_id
      end
    end
  end

  task :purge_failed_containers do
    set :cap_docker_compose_failed, true
    on roles(fetch(:docker_compose_roles)) do
      within release_path do
        execute :'docker-compose', 'down'
      end
      within fetch(:previous_release_path) do
        execute :'docker-compose', 'start', 'db'
        execute :'docker-compose', 'unpause', 'web'
      end
    end
  end

  task :pause_previous_release do
    on roles(fetch(:docker_compose_roles)) do
      if fetch(:previous_release_path, false)
        within fetch(:previous_release_path) do
          containers = capture :'docker-compose', 'ps', '-q'
          unless containers.empty?
            execute :'docker-compose', 'pause', 'web'
            execute :'docker-compose', 'stop', 'db'
          end
        end
        within release_path do
          execute :'docker-compose', 'restart', 'db'
          sleep 1
        end
      end
    end
  end

  task :unpause_previous_release do
    on roles(fetch(:docker_compose_roles)) do
      if fetch(:previous_release_path, false)
        within release_path do
          execute :'docker-compose', 'pause', 'web'
          execute :'docker-compose', 'stop', 'db'
        end
        within fetch(:previous_release_path) do
          execute :'docker-compose', 'start', 'db'
          execute :'docker-compose', 'unpause', 'web'
          sleep 1
        end
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
  before :migrate, :pause_previous_release
  #after :migrate, :unpause_previous_release
  before :publishing, :claim_files_by_container
  before :failed, :claim_files_by_container
  after :failed, :purge_failed_containers
  after :failed, :cleanup_rollback
  after :finished, :purge_old_containers unless fetch(:cap_docker_compose_failed, false)

end

namespace :load do
  task :defaults do
    set :docker_compose_roles, fetch(:docker_compose_roles, :all)
    set :previous_release_path, nil
  end
end
