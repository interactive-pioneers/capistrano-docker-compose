# Rewire key commands to container
%i(bundle rake).map do |command|
  # FIXME: replace hard-coded web service with master service setting
  # https://github.com/interactive-pioneers/capistrano-docker-compose/issues/7
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

  # TODO: extract to class and DRY up
  task :sync_persistant_volumes do
    on roles(fetch(:docker_compose_roles)) do
      if fetch(:docker_compose_persistant_volumes, false)
        info "Syncing persistant volume(s) #{fetch(:docker_compose_persistant_volumes).join(', ')}"
        within fetch(:previous_release_path) do
          compose_config = YAML.load_file("docker-compose-#{fetch(:rails_env)}.yml")
          info "Compose config fetched: #{compose_config}"
          compose_config['volumes'].to_a.each do |volume|
            current_volume = volume[0]
            info "Analysing volume #{current_volume}"
            if fetch(:docker_compose_persistant_volumes).include?(current_volume)
              info "#{current_volume} identified as persistant"
              compose_config['services'].to_a.each do |service|
                info "Checking #{service} service for volume #{current_volume}"
                service_volumes = service[1]['volumes']

                # FIXME: cycle through all service volumes
                if service_volumes && service_volumes[0] && service_volumes[0].split(':')[0] == current_volume && service_volumes[0].split(':').count > 1
                  persistant_path = service_volumes[0].split(':')[1]
                  info "Persistant path for #{current_volume} set to #{persistant_path}"
                  release_name = Pathname.new(fetch(:previous_release_path)).basename.to_s
                  container_id = capture("docker ps --filter 'name=#{release_name}_#{service[0]}'")
                  output_path = "/tmp/cap_docker_compose/#{container_id}/#{current_volume}"
                  info "Copying data from #{container_id}:#{persistant_path} to #{output_path}"
                  execute :docker, 'cp', "#{container_id}:#{persistant_path}", output_path
                  execute :rm, "#{output_path}/*.pid"

                  new_release_name = Pathname.new(release_path).basename.to_s
                  new_container_id = capture("docker ps --filter 'name=#{new_release_name}_#{service[0]}'")
                  info "Copying data from #{output_path} to #{new_container_id}:#{persistant_path}"
                  execute :docker, 'cp', output_path, "#{new_container_id}:#{persistant_path}"
                end
              end
            end
          end
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

  task :purge_failed_containers do
    set :cap_docker_compose_failed, true
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
  after :updating, :sync_persistant_volumes #if fetch(:previous_release_path, false)
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
