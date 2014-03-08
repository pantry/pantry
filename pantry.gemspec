$:.push File.expand_path("../lib", __FILE__)
require "pantry/version"

Gem::Specification.new do |s|
  s.name     = "pantry"
  s.version  = Pantry::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors  = ["Collective Idea", "Jason Roelofs"]
  s.email    = ["code@collectiveidea.com", "jasongroelofs@gmail.com"]
  s.license  = "MIT"
  s.homepage = "http://pantryops.org"

  s.summary     = "Modern DevOps Automation"
  s.description = <<-EOS
    Pantry is a framework that provides answers to common questions encoutered when setting up a DevOps, server configuration, or server provisioning pipeline.
  EOS

  s.required_ruby_version = ">= 2.0.0"

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- test/*`.split("\n")
  s.require_path = "lib"
  s.bindir       = "bin"

  s.executables  = %w(pantry-client pantry-server pantry)

  s.requirements << "zeromq 3.x or 4.x"
  s.requirements << "libsodium for Curve security"

  s.add_runtime_dependency "ffi-rzmq",         "~> 2.0",  ">= 2.0.0"
  s.add_runtime_dependency "celluloid",        "~> 0.15", ">= 0.15.0"
  s.add_runtime_dependency "celluloid-zmq",    "~> 0.15", ">= 0.15.0"
  s.add_runtime_dependency "highline",         "~> 1.6",  ">= 1.6.21"
  s.add_runtime_dependency "json",             "~> 1.8",  ">= 1.8.1"
  s.add_runtime_dependency "ruby-progressbar", "~> 1.4",  ">= 1.4.2"
  s.add_runtime_dependency "safe_yaml",        "~> 1.0",  ">= 1.0.1"

  s.add_development_dependency "mocha",  "~> 1.0", ">= 1.0.0"
  s.add_development_dependency "fakefs", "~> 0.5", ">= 0.5.1"
end
