Gem::Specification.new do |spec|
  spec.name           = "roda-live_reload"
  spec.version        = "0.1.0"
  spec.authors        = ["Adam Daniels"]
  spec.email          = "adam@mediadrive.ca"

  spec.homepage       = "https://github.com/adam12/roda-live_reload"
  spec.summary        = %q(Live reloading for Roda)
  spec.license        = "MIT"

  spec.files          = ["README.md"] + Dir["lib/**/*.rb"]
  spec.require_paths  = ["lib"]

  spec.add_dependency "roda", ">= 2.0.0"
  spec.add_dependency "listen", ">= 3.0.0"

  spec.add_development_dependency "rubygems-tasks", "~> 0.2"
end
