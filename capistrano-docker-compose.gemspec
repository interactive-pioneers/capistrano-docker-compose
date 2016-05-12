# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/docker/compose/version'

Gem::Specification.new do |spec|
  spec.name          = "capistrano-docker-compose"
  spec.version       = Capistrano::Docker::Compose::VERSION
  spec.authors       = ["Ain Tohvri"]
  spec.email         = ["at@interactive-pioneers.de"]

  spec.summary       = %q{Docker Compose specific tasks for Capistrano.}
  spec.description   = %q{Docker Compose specific tasks for Capistrano allowing seamless zero downtime containerised deployments.}
  spec.homepage      = "https://github.com/interactive-pioneers/capistrano-docker-compose"
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.license       = 'GPL-3.0'

  spec.add_dependency 'capistrano', '~> 3.5'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
