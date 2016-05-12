require "sshkit"
require "capistrano"
require "capistrano/docker/compose/version"
load File.expand_path("../tasks/compose.rake", __FILE__)
