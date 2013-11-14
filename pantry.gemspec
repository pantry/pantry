Gem::Specification.new do |s|
  s.name     = "pantry"
  s.version  = "0.0.0"
  s.platform = Gem::Platform::RUBY
  s.authors  = ["Collective Idea", "Jason Roelofs"]
  s.email    = ["code@collectiveidea.com", "jasongroelofs@gmail.com"]
  s.license  = "BSD"
  s.homepage = ""

  s.summary     = ""
  s.description = ""

  s.required_ruby_version = ">= 2.0.0"

  s.files        = Dir["README.md", "lib/**/*", "test/**/*"]
  s.test_files   = Dir["test/**/*"]
  s.require_path = "lib"
  s.bindir       = "bin"

  s.executables  = %w(pantry-client pantry-server)

  s.add_runtime_dependency "celluloid",     "~> 0.15.0"
  s.add_runtime_dependency "celluloid-zmq", "~> 0.15.0"
  s.add_runtime_dependency "json"
end
