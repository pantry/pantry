$:.push File.expand_path("../lib", __FILE__)
require "pantry/version"

Gem::Specification.new do |s|
  s.name     = "pantry"
  s.version  = Pantry::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors  = ["Collective Idea", "Jason Roelofs"]
  s.email    = ["code@collectiveidea.com", "jasongroelofs@gmail.com"]
  s.license  = "MIT"
  s.homepage = ""

  s.summary     = ""
  s.description = ""

  s.required_ruby_version = ">= 2.0.0"

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- test/*`.split("\n")
  s.require_path = "lib"
  s.bindir       = "bin"

  s.executables  = %w(pantry-client pantry-server pantry)

  s.add_runtime_dependency "ffi-rzmq",      "~> 2.0.0"
  s.add_runtime_dependency "celluloid",     "~> 0.15.0"
  s.add_runtime_dependency "celluloid-zmq", "~> 0.15.0"
  s.add_runtime_dependency "highline"
  s.add_runtime_dependency "json"
  s.add_runtime_dependency "ruby-progressbar"
  s.add_runtime_dependency "safe_yaml"

  # Chef stuff
  s.add_runtime_dependency "chef", "~> 11.10.0"
end
